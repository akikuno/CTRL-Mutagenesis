#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(rlang)
})

###############################################################################
# Argument parser
###############################################################################

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2 || any(args %in% c("-h", "--help"))) {
  cat(
    "Usage:\n",
    "  Rscript knee_exists.R <input.csv> <output.csv>\n\n",
    "Example:\n",
    "  Rscript knee_exists.R read_numbers_by_grnas.csv read_numbers_by_grnas.exists.csv\n",
    sep = ""
  )
  quit(status = 1)
}

input_csv <- args[[1]]
output_csv <- args[[2]]

###############################################################################
# Validation
###############################################################################

required_cols <- c("sample_name", "index", "read number")

df <- read_csv(input_csv, show_col_types = FALSE)

missing_cols <- setdiff(required_cols, names(df))

if (length(missing_cols) > 0) {
  stop(
    "Missing required column(s): ",
    paste(missing_cols, collapse = ", ")
  )
}

original_cols <- names(df)

###############################################################################
# First derivative based on 3-point Lagrange interpolation
###############################################################################

cfd_lagrange <- function(x, y) {
  n <- length(x)

  if (n < 3) {
    stop("At least three points are required.")
  }

  if (any(duplicated(x))) {
    stop("x values must be unique.")
  }

  derivative <- numeric(n)

  for (i in seq_len(n)) {
    if (i == 1) {
      idx <- 1:3
    } else if (i == n) {
      idx <- (n - 2):n
    } else {
      idx <- (i - 1):(i + 1)
    }

    xs <- x[idx]
    ys <- y[idx]
    x0 <- x[i]

    d <- 0

    for (k in 1:3) {
      others <- setdiff(1:3, k)
      denom <- prod(xs[k] - xs[others])

      basis_derivative <- 0

      for (m in others) {
        remaining <- setdiff(others, m)
        basis_derivative <- basis_derivative +
          prod(x0 - xs[remaining]) / denom
      }

      d <- d + ys[k] * basis_derivative
    }

    derivative[i] <- d
  }

  derivative
}

###############################################################################
# Second derivative based on 3-point Lagrange interpolation
###############################################################################

csd_lagrange <- function(x, y) {
  n <- length(x)

  if (n < 3) {
    stop("At least three points are required.")
  }

  if (any(duplicated(x))) {
    stop("x values must be unique.")
  }

  second_derivative <- numeric(n)

  for (i in seq_len(n)) {
    if (i == 1) {
      idx <- 1:3
    } else if (i == n) {
      idx <- (n - 2):n
    } else {
      idx <- (i - 1):(i + 1)
    }

    xs <- x[idx]
    ys <- y[idx]

    d2 <- 0

    for (k in 1:3) {
      others <- setdiff(1:3, k)
      denom <- prod(xs[k] - xs[others])

      basis_second_derivative <- 2 / denom
      d2 <- d2 + ys[k] * basis_second_derivative
    }

    second_derivative[i] <- d2
  }

  second_derivative
}

###############################################################################
# Curvature-based knee detection
###############################################################################

knee_curvature_index <- function(points, reads, z_min = 3) {
  x <- points[, 1]
  y <- points[, 2]

  gradient1 <- cfd_lagrange(x, y)
  gradient2 <- csd_lagrange(x, y)

  curvature <- abs(gradient2) / ((1 + gradient1^2)^1.5)

  n <- length(reads)

  a <- reads[-n]
  b <- reads[-1]

  drop_z <- log((a + 0.5) / (b + 0.5)) /
    sqrt(1 / (a + 0.5) + 1 / (b + 0.5))

  # drop_z[i]は、rank i -> rank i+1 の落ち込みに対応する
  # curvature[i]とdrop_z[i]を対応させる
  score <- rep(NA_real_, n)
  score[1:(n - 1)] <- curvature[1:(n - 1)] * pmax(drop_z, 0)


  # 端は除外
  candidate_idx <- 2:(n - 1)

  # z-scoreが小さい落ち込みはknee候補から除外
  valid_idx <- candidate_idx[drop_z[candidate_idx] >= z_min]

  if (length(valid_idx) == 0) {
    return(
      list(
        index = NA_integer_,
        curvature = curvature,
        drop_z = c(drop_z, NA_real_),
        score = score,
        valid = FALSE
      )
    )
  }

  idx <- valid_idx[which.max(score[valid_idx])]

  list(
    index = idx,
    curvature = curvature,
    drop_z = c(drop_z, NA_real_),
    score = score,
    valid = TRUE
  )
}

add_exists_by_knee <- function(.data, value_col) {
  value_col <- enquo(value_col)

  has_id_col <- "id" %in% names(.data)

  .data <- .data %>%
    mutate(
      .row_id = row_number(),
      .value = as.numeric(!!value_col),
      .is_no = if (has_id_col) {
        trimws(tolower(as.character(id))) == "no"
      } else {
        FALSE
      }
    )

  if (any(is.na(.data$.value))) {
    stop("The read count column contains NA or non-numeric values.")
  }

  if (nrow(.data) < 3) {
    return(
      .data %>%
        mutate(exists = "False") %>%
        arrange(.row_id) %>%
        select(-.row_id, -.value, -.is_no)
    )
  }

  sorted <- .data %>%
    arrange(desc(.value)) %>%
    mutate(
      .rank = row_number(),
      .log_value = log10(pmax(.value, 1))
    )

  points_mat <- sorted %>%
    select(.rank, .log_value) %>%
    as.matrix()

  res <- knee_curvature_index(points_mat, sorted$.value)

  # If no valid knee is detected, set all rows to False.
  if (!res$valid || is.na(res$index)) {
    return(
      sorted %>%
        mutate(exists = "False") %>%
        arrange(.row_id) %>%
        select(-.row_id, -.value, -.rank, -.log_value, -.is_no)
    )
  }

  threshold <- sorted$.value[res$index]

  # If the threshold is NA, set all rows to False.
  if (is.na(threshold)) {
    return(
      sorted %>%
        mutate(exists = "False") %>%
        arrange(.row_id) %>%
        select(-.row_id, -.value, -.rank, -.log_value, -.is_no)
    )
  }

  sorted %>%
    mutate(
      exists = if_else(.value >= threshold, "True", "False"),
      exists = if_else(.is_no, "False", exists)
    ) %>%
    arrange(.row_id) %>%
    select(-.row_id, -.value, -.rank, -.log_value, -.is_no)
}


###############################################################################
# Run
###############################################################################

df_out <- df %>%
  group_by(sample_name, index) %>%
  group_modify(~ add_exists_by_knee(.x, `read number`)) %>%
  ungroup() %>%
  select(all_of(original_cols), exists)

write_csv(df_out, output_csv)



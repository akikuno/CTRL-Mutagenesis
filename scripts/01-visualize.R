suppressPackageStartupMessages({
    library(tidyverse)
})


readnum <- read_csv(str_glue("reports/{Sys.Date()}/read_numbers_by_grnas.csv"), show_col_types = FALSE)

readnum <-
    readnum %>%
    mutate(sample_name = fct_inorder(sample_name)) %>%
    group_by(sample_name, index) %>%
    mutate(total_reads = sum(`read number`)) %>%
    mutate(per_reads = `read number` / total_reads * 100)

###############################################################################
# Visualization
###############################################################################

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

width <- 15
height <- 50
ncol <- 4

for (arg in args) {
    if (grepl("^-w=", arg)) {
        width <- as.numeric(sub("^-w=", "", arg))
    } else if (grepl("^-h=", arg)) {
        height <- as.numeric(sub("^-h=", "", arg))
    } else if (grepl("^-ncol=", arg)) {
        ncol <- as.numeric(sub("^-ncol=", "", arg))
    }
}


# Confirm the color palette
num_id <- length(unique(readnum$id))
colors <- rep(palette.colors(), length.out = num_id)

g_count <-
    ggplot(readnum, aes(x = id, y = `read number`, fill = id)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = colors) +
    theme_bw() +
    theme(plot.background = element_rect(fill = "white")) +
    facet_wrap(~ sample_name + index, scale = "free_y", ncol = ncol)

g_percent <-
    ggplot(readnum, aes(x = id, y = per_reads, fill = id)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = colors) +
    theme_bw() +
    theme(plot.background = element_rect(fill = "white")) +
    facet_wrap(~ sample_name + index, scale = "free_y", ncol = ncol)

# Save the plots
ggsave(str_glue("reports/{Sys.Date()}/read_count.png"), g_count, width = width, height = height, limitsize = FALSE)
ggsave(str_glue("reports/{Sys.Date()}/read_count.pdf"), g_count, width = width, height = height, limitsize = FALSE)

ggsave(str_glue("reports/{Sys.Date()}/read_percent.png"), g_percent, width = width, height = height, limitsize = FALSE)
ggsave(str_glue("reports/{Sys.Date()}/read_percent.pdf"), g_percent, width = width, height = height, limitsize = FALSE)


# Done
cat(str_glue("Done! Have a look at reports/{Sys.Date()}"))
cat("\n")

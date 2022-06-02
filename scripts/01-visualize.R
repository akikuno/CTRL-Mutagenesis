library(tidyverse)
library(RColorBrewer)

readnum <- read_csv(str_glue("reports/{Sys.Date()}/read_numbers_by_grnas.csv"))

readnum <-
    readnum %>%
    mutate(sample_name = fct_inorder(sample_name)) %>%
    group_by(sample_name, index) %>%
    mutate(total_reads = sum(`read number`)) %>%
    mutate(per_reads = `read number` / total_reads * 100)

###############################################################################
# Visualization
###############################################################################

colors <- colorRampPalette(brewer.pal(8, "Set2"))(18)

g_count <-
    ggplot(readnum, aes(x = id, y = `read number`, fill = id)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = colors) +
    theme_bw() +
    theme(plot.background = element_rect(fill = "white")) +
    facet_wrap(~ sample_name + index, scale = "free_y", ncol = 4)

ggsave(str_glue("reports/{Sys.Date()}/read_count.png"), g_count, width = 15, height = 50, limitsize = FALSE)
ggsave(str_glue("reports/{Sys.Date()}/read_count.pdf"), g_count, width = 15, height = 50, limitsize = FALSE)

g_percent <-
    ggplot(readnum, aes(x = id, y = per_reads, fill = id)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = colors) +
    theme_bw() +
    theme(plot.background = element_rect(fill = "white")) +
    facet_wrap(~ sample_name + index, scale = "free_y", ncol = 4)

ggsave(str_glue("reports/{Sys.Date()}/read_percent.png"), g_percent, width = 15, height = 50, limitsize = FALSE)
ggsave(str_glue("reports/{Sys.Date()}/read_percent.pdf"), g_percent, width = 15, height = 50, limitsize = FALSE)
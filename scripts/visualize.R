library(tidyverse)
library(RColorBrewer)

colors <- colorRampPalette(brewer.pal(8, "Set2"))(18)

readnum <- read_csv("reports/read_numbers_by_grnas.csv")

g <-
    ggplot(readnum, aes(x = id, y = `read number`, fill = id)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = colors) +
    theme_bw() +
    theme(plot.background = element_rect(fill = "white")) +
    facet_wrap(~ sample_name + index, scale = "free_y", ncol = 4)

ggsave("reports/read_count.png", g, width = 15, height = 20)
ggsave("reports/read_count.pdf", g, width = 15, height = 20)
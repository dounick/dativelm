library(ggplot2)
library(ggrepel)
library(dplyr)

models <- c("default", "balanced", "no-datives", "no-2postverbal", "swapped-datives", "short-first", "random-first", "long-first", "long-first-headfinal")

perplexity11 <- c(55.8783, 56.7330, 54.7594, 52.5822, 56.8073, 58.7264, 68.9270, 65.0329, 84.4295)
perplexity21 <- c(56.0843, 56.2217, 54.6205, 53.3849, 56.2284, 59.4645, 69.7249, 65.7562, 83.4488)
perplexity31 <- c(56.0703, 56.4282, 54.9127, 52.9432, 55.8687, 59.0923, 70.0242, 65.3294, 84.4588)
length_correlation11 <- c(-0.42, -0.33, -0.25, -0.22, -0.02, -0.26, -0.16, -0.08, 0.09)
length_correlation21 <- c(-0.44, -0.33, -0.24, -0.22, 0.03, -0.23, -0.14, -0.05, 0.06)
length_correlation31 <- c(-0.43, -0.35, -0.22, -0.22, -0.02, -0.21, -0.12, -0.04, 0.13)

perplexity12 <- c(72.4579, 68.1873, 95.8001, 88.7164, 66.2403, 126.7526, 128.9045, 237.4193, 489.0652)
perplexity22 <- c(68.7662, 67.9749, 93.5631, 95.3959, 65.7810, 126.1385, 131.3553, 231.2658, 490.2303)
perplexity32 <- c(70.9149, 68.3654, 97.5819, 92.1907, 65.2441, 126.5920, 128.7704, 245.2448, 479.1083)
length_correlation12 <- c(-0.42, -0.33, -0.25, -0.22, -0.02, -0.26, -0.16, -0.08, 0.09)
length_correlation22 <- c(-0.44, -0.33, -0.24, -0.22, 0.03, -0.23, -0.14, -0.05, 0.06)
length_correlation32 <- c(-0.43, -0.35, -0.22, -0.22, -0.02, -0.21, -0.12, -0.04, 0.13)

generate_color <- function(value, min_val, max_val, low_color = "#0000ff", mid_color = "#000080", high_color = "#000000") {
  if (max_val == min_val) {
    normalized_value = 0.5
  } else {
    normalized_value = (value - min_val) / (max_val - min_val)
  }
  color_func <- colorRamp(c(low_color, mid_color, high_color))
  rgb_values <- color_func(normalized_value)
  return(rgb(rgb_values[1], rgb_values[2], rgb_values[3], maxColorValue = 255))
}

direct_shortness <- c(-0.329, 0, 0, 0, 0.329)
indirect_shortness <- c(0.238, 0.385, 0.532, 0.65)
direct_colors <- sapply(direct_shortness, function(val) generate_color(val, -0.329, 0.329, "#b59410ff", "#7bc043ff", "#0392cfff"))
indirect_colors <- sapply(indirect_shortness, function(val) generate_color(val, 0.238, 0.65, "#b59410ff", "#f37736ff", "#ee4035ff"))
model_colors <- c(direct_colors, indirect_colors)
names(model_colors) <- models

model_data_long_1 <- data.frame(
  Model = rep(models, 3),
  Perplexity = c(perplexity11, perplexity21, perplexity31),
  LengthCorrelation = c(length_correlation11, length_correlation21, length_correlation31),
  Seed = rep(c("Seed 1", "Seed 2", "Seed 3"), each = length(models))
) %>%
  mutate(
    color = model_colors[Model],
    Plot = "Plot 1"
  )

seed_pairs_1 <- rbind(
  data.frame(
    Model = models,
    x = perplexity11, 
    y = length_correlation11,
    xend = perplexity21, 
    yend = length_correlation21
  ),
  data.frame(
    Model = models,
    x = perplexity21, 
    y = length_correlation21,
    xend = perplexity31, 
    yend = length_correlation31
  ),
  data.frame(
    Model = models,
    x = perplexity31, 
    y = length_correlation31,
    xend = perplexity11, 
    yend = length_correlation11
  )
) %>%
  mutate(
    color = model_colors[Model],
    Plot = "Plot 1"
  )

hull_data_1 <- model_data_long_1 %>%
  group_by(Model) %>%
  slice(chull(Perplexity, LengthCorrelation)) %>%
  mutate(
    color = model_colors[Model],
    Plot = "Plot 1"
  )

model_data_long_2 <- data.frame(
  Model = rep(models, 3),
  Perplexity = c(perplexity12, perplexity22, perplexity32),
  LengthCorrelation = c(length_correlation12, length_correlation22, length_correlation32),
  Seed = rep(c("Seed 1", "Seed 2", "Seed 3"), each = length(models))
) %>%
  mutate(
    color = model_colors[Model],
    Plot = "Plot 2"
  )

seed_pairs_2 <- rbind(
  data.frame(
    Model = models,
    x = perplexity12, 
    y = length_correlation12,
    xend = perplexity22, 
    yend = length_correlation22
  ),
  data.frame(
    Model = models,
    x = perplexity22, 
    y = length_correlation22,
    xend = perplexity32, 
    yend = length_correlation32
  ),
  data.frame(
    Model = models,
    x = perplexity32, 
    y = length_correlation32,
    xend = perplexity12, 
    yend = length_correlation12
  )
) %>%
  mutate(
    color = model_colors[Model],
    Plot = "Plot 2"
  )

hull_data_2 <- model_data_long_2 %>%
  group_by(Model) %>%
  slice(chull(Perplexity, LengthCorrelation)) %>%
  mutate(
    color = model_colors[Model],
    Plot = "Plot 2"
  )

combined_data <- bind_rows(model_data_long_1, model_data_long_2)
combined_seed_pairs <- bind_rows(seed_pairs_1, seed_pairs_2)
combined_hull_data <- bind_rows(hull_data_1, hull_data_2)

library(patchwork)
library(grid)

library(patchwork)

plot1 <- ggplot(combined_hull_data %>% filter(Plot == "Plot 1") %>% filter(Model %in% c("default", "balanced", "no-datives", "no-2postverbal", "swapped-datives"))) +
  geom_polygon(aes(x = Perplexity, y = LengthCorrelation, fill = color, group = interaction(Model, Plot)),
               alpha = 0.5) +
  geom_segment(data = combined_seed_pairs %>% filter(Plot == "Plot 1")
               %>% filter(Model %in% c("default", "balanced", "no-datives", "no-2postverbal", "swapped-datives")), 
               aes(x = x, y = y, xend = xend, yend = yend, color = color),
               alpha = 0.8, linetype = "dotted") +
  geom_point(data = combined_data %>% filter(Plot == "Plot 1")
             %>% filter(Model %in% c("default", "balanced", "no-datives", "no-2postverbal", "swapped-datives")), 
             aes(x = Perplexity, y = LengthCorrelation, color = color),
             size = 3, alpha = 0.8) +
  geom_text_repel(data = combined_data %>%
                    filter(Plot == "Plot 1") %>%
                    filter(Model %in% c("default", "balanced", "no-datives", "no-2postverbal", "swapped-datives")) %>%
                    group_by(Model) %>%
                    summarize(AvgPerplexity = mean(Perplexity),
                              AvgLengthCorrelation = mean(LengthCorrelation),
                              color = first(color)),
                  aes(x = AvgPerplexity, y = AvgLengthCorrelation, label = Model, color = color),
                  box.padding = 2,
                  point.padding = 0.5,
                  segment.curvature = -0.1,
                  segment.ncp = 3,
                  segment.angle = 20,
                  force = 3,
                  size = 5, show.legend = FALSE, family = "Inconsolata", fontface = "bold") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "darkgrey") +
  scale_color_identity(aesthetics = c("color", "fill")) +
  scale_x_continuous(limits = c(50, 70)) +
  scale_y_continuous(limits = c(-0.45, 0.15)) +
  theme_classic(base_family = "Palatino", base_size = 16) +
  labs(
    x = NULL,
    y = "Length Effect"
  ) +
  theme(
    plot.title = element_blank(),
    plot.caption = element_text(hjust = 0),
    legend.position = "none"
  )

plot2 <- ggplot(combined_hull_data %>% filter(Plot == "Plot 1") %>% filter(Model %in% c("short-first", "random-first", "long-first", "long-first-headfinal"))) +
  geom_polygon(aes(x = Perplexity, y = LengthCorrelation, fill = color, group = interaction(Model, Plot)),
               alpha = 0.1) +
  geom_segment(data = combined_seed_pairs %>% filter(Plot == "Plot 1") %>% filter(Model %in% c("short-first", "random-first", "long-first", "long-first-headfinal")), 
               aes(x = x, y = y, xend = xend, yend = yend, color = color),
               alpha = 0.4, linetype = "dotted") +
  geom_point(data = combined_data %>% filter(Plot == "Plot 1") %>%
               filter(Model %in% c("short-first", "random-first", "long-first", "long-first-headfinal")), 
             aes(x = Perplexity, y = LengthCorrelation, color = color),
             size = 3, alpha = 0.8) +
  geom_text_repel(data = combined_data %>%
                    filter(Plot == "Plot 1") %>% 
                    filter(Model %in% c("short-first", "random-first", "long-first", "long-first-headfinal")) %>%
                    group_by(Model) %>%
                    summarize(AvgPerplexity = mean(Perplexity),
                              AvgLengthCorrelation = mean(LengthCorrelation),
                              color = first(color)),
                  aes(x = AvgPerplexity, y = AvgLengthCorrelation, label = Model, color = color),
                  box.padding = 2,
                  point.padding = 0.5,
                  segment.curvature = -0.1,
                  segment.ncp = 3,
                  segment.angle = 20,
                  force = 3,
                  size = 5, show.legend = FALSE, family = "Inconsolata", fontface = "bold") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "darkgrey") +
  scale_color_identity(aesthetics = c("color", "fill")) +
  scale_x_continuous(limits = c(50, 100)) +
  scale_y_continuous(limits = c(-0.45, 0.15)) + 
  theme_classic(base_family = "Palatino", base_size = 16) +
  labs(
    x = NULL,
    y = NULL
  ) +
  theme(
    plot.title = element_blank(),
    plot.caption = element_text(hjust = 0),
    legend.position = "right",
    legend.box = "vertical"
  )
combined_plot <- plot1 + plot2 + 
  plot_layout(ncol = 2) +
  plot_annotation(
    caption = "Perplexity on Validation Set", 
    theme = theme(
      plot.caption = element_text(
        hjust = 0.5,  
        size = 16, 
        family = "Palatino"
      )
    )
  )

# ggsave("paper/combined_perplexity.svg", combined_plot,  dpi=300, height = 5.29, width=14)
ggsave("paper/combined_perplexity.pdf", combined_plot,  dpi=300, height = 5.29, width=14, device=cairo_pdf)

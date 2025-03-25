
library(tidyverse)
library(ggtext)
library(plotrix)
library(patchwork)
library(ggplot2)

rawdata <- read_csv("analysis/all_data.csv")

filter(rawdata, is.na(recipient_pos_spacy)) %>%
  select(sentence, recipient_pos, recipient_pos_spacy)

d =  rawdata %>%
  select(global_idx, recipient_pos, recipient_anim, theme_pos, theme_anim,
         loose_default_best:long_first_headfinal_best,
         length_difference,
         verb_lemma) %>%
  pivot_longer(cols=loose_default_best:long_first_headfinal_best, names_to = "condition", values_to = "score") %>% 
  mutate(recipient_pos = ifelse(recipient_pos == "PRON" , "pronoun", "NP"),
         theme_pos = ifelse(theme_pos == "PRON" , "pronoun", "NP")) %>%
  mutate(condition = str_replace(condition, "(_small)?_best", "")) %>%
  mutate(
    condition = factor(
      condition, 
      levels = c("loose_default", "loose_balanced", "counterfactual", "datives_removed", "ditransitives_removed", "short_first", "random_first", "long_first", "long_first_headfinal"),
      labels = c("default", "balanced", "swapped\ndatives","no-datives", "no-2postverbal", 
                 "short-first", "random-first", "long-first", "long-first\nheadfinal")
    )
  )


d %>% count(condition)

filter(rawdata, is.na(recipient_pos_spacy)) %>%
  select(sentence, recipient_pos, recipient_pos_spacy)

seeded <- rawdata %>%
  select(global_idx, recipient_pos, recipient_anim, theme_pos, theme_anim,
         loose_default_ratio63:long_first_headfinal_ratio42,
         length_difference,
         verb_lemma) %>%
  pivot_longer(
    cols = c(
      matches("loose_default_ratio\\d+"),
      matches("loose_balanced_ratio\\d+"),
      matches("datives_removed_ratio\\d+"),
      matches("ditransitives_removed_ratio\\d+"),
      matches("counterfactual_ratio\\d+"),
      matches("short_first_ratio\\d+"),
      matches("random_first_ratio\\d+"),
      matches("long_first_ratio\\d+"),
      matches("long_first_headfinal_ratio\\d+")
    ), 
    names_to = "condition_seed", 
    values_to = "score"
  ) %>%
  mutate(
    seed = as.integer(str_extract(condition_seed, "\\d+")),
    condition = str_replace(condition_seed, "_ratio\\d+", "")
  ) %>%
  mutate(
    recipient_pos = ifelse(recipient_pos == "PRON" | is.na(recipient_pos), "pronoun", "NP"),
    theme_pos = ifelse(theme_pos == "PRON" | is.na(theme_pos), "pronoun", "NP")
  ) %>%
  mutate(
    condition = factor(
      condition, 
      levels = c("loose_default", "loose_balanced", "counterfactual", "datives_removed", "ditransitives_removed", "short_first", "random_first", "long_first", "long_first_headfinal"),
      labels = c("default", "balanced", "swapped\ndatives","no-datives", "no-ditransitives", 
                 "short-first", "random-first", "long-first", "long-first\nheadfinal")
    )
  )

seeded %>% count(condition)

seeded$recipient_animacy = ifelse(seeded$recipient_anim == "i", -.5, .5)
seeded$theme_animacy = ifelse(seeded$theme_anim == "i", -.5, .5)
seeded$theme_pos = ifelse(seeded$theme_pos == "pronoun", .5, -.5)
seeded$recipient_pos = ifelse(seeded$recipient_pos == "pronoun", .5, -.5)

seeded$animacy_contrast = ifelse(seeded$recipient_animacy == seeded$theme_animacy, 0,
                            ifelse(seeded$recipient_animacy > seeded$theme_animacy, 1, -1))

seeded$pos_contrast = ifelse(seeded$recipient_pos > seeded$theme_pos, 1, 0)
seeded %>% count(condition, seed)



slopes2 = d %>%
  group_by(condition) %>%
  summarise(slope = cor(score, length_difference)) %>%
  mutate(x = -1.85, y=1.15,
         val = paste("<i>r</i> =",as.character(format(round(slope, 2), nsmall=2))))

plot2_data = d %>%
  group_by(length_difference, condition) %>%
  summarise(m = mean(score), .groups = "drop")

length_plot <- plot2_data %>%
  ggplot(aes(x = length_difference, y = m)) +
  geom_point(size = 3, alpha = 0.5, color = "black") +
  facet_wrap(~condition, nrow = 1) + 
  geom_smooth(method = "lm") +
  geom_richtext(
    data = slopes2, 
    aes(x = x, y = y, label = val), 
    size = 6, 
    family = "CMU Serif", 
    color = "black",
    fill = "cornsilk"
  ) +
  theme_bw(base_size = 24, base_family = "Palatino") +
  theme(
    panel.grid = element_blank(),
    strip.text = element_text(family = "Inconsolata", face = "bold", size = 22),
    axis.text = element_text(color = "black"),
    strip.background = element_blank()
  ) +
  labs(
    y = NULL,
    x = "Log Difference in Recipient and Theme Lengths",
  )

animacy_plot <- seeded %>%
  group_by(animacy_contrast, condition, seed) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(score),
    score = mean(score),
    .groups = "drop"
  ) %>%
  ungroup() %>%
  mutate(
    animacy_contrast = case_when(
      animacy_contrast == -1 ~ "L",
      animacy_contrast == 0 ~ "E",
      animacy_contrast == 1 ~ "M"
    ),
    animacy_contrast = fct_relevel(animacy_contrast, "L", "E", "M")
  ) %>%
  ggplot(aes(animacy_contrast, score, group = seed)) +
  geom_line() +
  geom_point(size = 3, alpha = 0.5) +
  geom_linerange(aes(ymin = score-ste, ymax = score+ste)) +
  scale_y_continuous(limits = c(-0.82, 0.1)) +
  facet_wrap(~condition, nrow=1) +
  theme_bw(base_size = 24, base_family = "Palatino") +
  theme(
    panel.grid = element_blank(),
    axis.text = element_text(color = "black"),
    strip.background = element_blank(),
    strip.text = element_blank()
    ) +
  labs(
    x = bquote(paste("Recipient ", bold("L"), "ess, ", bold("E"), "qually, or ", bold("M"), "ore animate")),
    y = NULL,
  )

pronoun_plot <- seeded %>%
  group_by(pos_contrast, condition, seed) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(score),
    score = mean(score),
    .groups = "drop"
  ) %>%
  ungroup() %>%
  mutate(
    pos_contrast = case_when(
      pos_contrast == 0 ~ "L",
      pos_contrast == 1 ~ "M"
    ),
    pos_contrast = fct_relevel(pos_contrast, "L", "M")
  ) %>%
  filter(!condition %in% c("Unablated (Strict)", "Balanced (Strict)")) %>%
  ggplot(aes(pos_contrast, score, group = seed)) +
  geom_line() +
  geom_point(size = 2) +
  geom_linerange(aes(ymin = score-ste, ymax = score+ste)) +
  scale_y_continuous(limits = c(-0.82, 0.1)) +
  facet_wrap(~condition, nrow=1) +
  theme_bw(base_size = 24, base_family = "Palatino") +
  theme(
    panel.grid = element_blank(),
    axis.text = element_text(color = "black"),
    strip.background = element_blank(),
    strip.text = element_blank()
    ) +
  labs(
    x = bquote(paste("Recipient ", bold("L"), "ess/equally or ", bold("M"), "ore pronominal")),
    y = NULL,
  )

combined_plot <- length_plot / animacy_plot +
  plot_layout(heights = c(1, 0.6))
combined_plot <- wrap_elements(combined_plot) +
  labs(tag = "DO Preference") +
  theme(
    plot.tag = element_text(size = 24, angle = 90, family = "Palatino"),
    plot.tag.position = "left"
  )

# ggsave("paper/combined.svg", combined_plot, dpi = 300, height = 8, width = 24)
ggsave("paper/combined.pdf", combined_plot, dpi = 300, height = 8, width = 24, device=cairo_pdf)
combined_plot

library(tidyverse)
library(ggtext)
# library(extrafont)

hawkins_raw <- read_csv("analysis/hawkins_results.csv")

results <- hawkins_raw %>%
  filter(verb_count >= 1) %>%
  select(i,verb_id, classification, behavior=BehavDOpreference, gpt2_ratio, loose_default_ratio) %>% 
  rename(default_ratio = loose_default_ratio) %>%
  mutate(
    behavior = behavior/100,
    behavior = behavior - min(behavior)/(max(behavior) - min(behavior)),
    gpt2_ratio = gpt2_ratio - min(gpt2_ratio)/(max(gpt2_ratio) - min(gpt2_ratio)),
    default_ratio = default_ratio - min(default_ratio)/(max(default_ratio) - min(default_ratio)),
  ) %>%
  group_by(verb_id, classification) %>%
  summarize(
    behavior = mean(behavior),
    gpt2_ratio = mean(gpt2_ratio),
    default_ratio = mean(default_ratio),
  ) %>%
  ungroup()
  
  

rho <- results %>%
  summarize(
    gpt2 = cor(gpt2_ratio, behavior, method = "pearson"),
    default = cor(default_ratio, behavior, method = "pearson"),
  ) %>%
  pivot_longer(gpt2:default, names_to = "condition", values_to = "r") %>%
  mutate(
    x = 0.6, y = case_when(condition == "gpt2" ~ -5, TRUE ~ -1),
    r = sprintf("<i>r</i> = %.2f", round(r, digits = 2))
  ) %>%
  mutate(condition = factor(condition, levels = c("default", "gpt2"), labels = c("Unablated", "GPT-2 Small")))
  

results %>%
  pivot_longer(gpt2_ratio:default_ratio, names_to = "condition", values_to = "do_pref") %>%
  mutate(condition = str_remove(condition, "_ratio")) %>%
  # mutate(condition = factor(condition, levels = c("default", "balanced"), labels = c("Strict (unablated)", "Strict (balanced)"))) %>%
  mutate(condition = factor(condition, levels = c("default", "gpt2"), labels = c("Unablated","GPT-2 Small"))) %>%
  filter(condition %in% c("Unablated", "GPT-2 Small")) %>%
  mutate(classification = case_when(classification == "alternating" ~ "Alternating", TRUE ~ "Non-alternating")) %>%
  ggplot(aes(behavior, do_pref, color = classification)) +
  geom_point(size = 2, alpha = 0.6) +
  geom_smooth(aes(group=NA), method = "lm", color = "black") +
  geom_richtext(
    data=rho %>% filter(condition %in% c("Unablated", "GPT-2 Small")), 
    aes(x=x, y=y, label=r), size=4, family="Palatino", color = "black"
  ) +
  # scale_y_continuous(breaks = scales::pretty_breaks(6)) +
  guides(color = guide_legend(override.aes = list(size=4))) +
  facet_wrap(~ condition, scales = "free_y") +
  scale_color_manual(values = c("#018571", "#a6611a")) +
  theme_bw(base_size = 18, base_family="Palatino") +
  theme(
    legend.position = "top",
    panel.grid = element_blank(),
    legend.text = element_text(size = 16),
    # strip.text.x = element_text(family="Inconsolata", face="bold")
  ) +
  labs(
    x = "Human Judgment",
    y = "DO preference",
    color = "Classification"
  )

ggsave("paper/hawkins-comparison.pdf", height=3.8, width=6.30, dpi=300, device=cairo_pdf)



results %>%
  pivot_longer(gpt2_ratio:default_ratio, names_to = "condition", values_to = "do_pref") %>%
  mutate(condition = str_remove(condition, "_ratio")) %>%
  # mutate(condition = factor(condition, levels = c("default", "balanced"), labels = c("Strict (unablated)", "Strict (balanced)"))) %>%
  mutate(condition = factor(condition, levels = c("default", "gpt2"), labels = c("Unablated","GPT-2 Small"))) %>%
  filter(condition %in% c("Unablated", "GPT-2 Small")) %>%
  mutate(classification = case_when(classification == "alternating" ~ "Alternating", TRUE ~ "Non-alternating")) %>%
  ggplot(aes(behavior, do_pref, color = classification)) +
  geom_point(size = 2, alpha = 0.6) +
  geom_smooth(aes(group=NA), method = "lm", color = "black") +
  geom_richtext(
    data=rho %>% filter(condition %in% c("Unablated", "GPT-2 Small")), 
    aes(x=x, y=y, label=r), size=4, family="Palatino", color = "black"
  ) +
  # scale_y_continuous(breaks = scales::pretty_breaks(6)) +
  facet_wrap(~ condition, scales = "free_y", nrow = 2) +
  scale_color_manual(values = c("#018571", "#a6611a")) +
  theme_bw(base_size = 18, base_family="Palatino") +
  theme(
    legend.position = "top",
    panel.grid = element_blank()
  ) +
  guides(color = guide_legend(nrow=2)) +
  labs(
    x = "Human Judgment",
    y = "DO preference",
    color = "Classification"
  )

ggsave("paper/hawkins-comparison-vertical.pdf", height=7.63, width=3.98, dpi=300, device=cairo_pdf)


library(tidyverse)
library(ggtext)
library(patchwork)

rawdata <- read_csv("analysis/all_data-manual.csv")

rawdata %>% 
  count(verb_lemma, recipient_anim, sort=TRUE) %>%
  write_csv("analysis/verb-recipient-animacy.csv")

rawdata %>% 
  count(verb_lemma, recipient_anim, sort=TRUE) %>%
  pivot_wider(names_from=recipient_anim, values_from = n) %>%
  mutate(diff = i-a) %>%
  View()

rawdata %>% 
  count(verb_lemma, recipient, sort=TRUE) %>%
  write_csv("analysis/verb-recipient.csv")

filter(rawdata, is.na(recipient_pos_spacy)) %>%
  select(sentence, recipient_pos, recipient_pos_spacy)

d <- rawdata %>%
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
    recipient_pos = ifelse(recipient_pos == "PRON", "pronoun", "NP"),
    theme_pos = ifelse(theme_pos == "PRON", "pronoun", "NP")
  ) %>%
  mutate(
    condition = factor(
      condition, 
      levels = c("loose_default", "loose_balanced", "datives_removed", "ditransitives_removed", "counterfactual", "short_first", "random_first", "long_first", "long_first_headfinal"),
      labels = c("Unablated (Loose)", "Balanced (Loose)", "No Datives", "No Ditransitives", "Swapped Datives",
                 "Short-first\n(No Ditransitives)", "Random-first\n(No Ditransitives)", "Long-first\n(No Ditransitives)", "Long-first\n(Head Final)")
    )
  )

d %>% count(condition)

library(lme4)

d$recipient_animacy = ifelse(d$recipient_anim == "i", -.5, .5)
d$theme_animacy = ifelse(d$theme_anim == "i", -.5, .5)
d$theme_pos = ifelse(d$theme_pos == "pronoun", .5, -.5)
d$recipient_pos = ifelse(d$recipient_pos == "pronoun", .5, -.5)

d$animacy_contrast = ifelse(d$recipient_animacy == d$theme_animacy, 0,
                            ifelse(d$recipient_animacy > d$theme_animacy, 1, -1))

d$pos_contrast = ifelse(d$recipient_pos == d$theme_pos, 0,
                        ifelse(d$recipient_pos > d$theme_pos, 1, -1))

#####################################################
library(lmerTest)
d.all <- lmerTest::lmer(score ~ condition*length_difference + condition*animacy_contrast + 
               (1 +  length_difference + animacy_contrast || verb_lemma) + 
               (1 +  length_difference  + animacy_contrast || seed), REML=FALSE,
             data = d, control=lmerControl(optimizer="bobyqa"))

just.manip = filter(d, grepl("-first", condition))
just.manip$condition = factor(just.manip$condition, 
                              levels = c("Random-first\n(No Ditransitives)",
                                         "Short-first\n(No Ditransitives)",
                                         "Long-first\n(No Ditransitives)",
                                         "Long-first\n(Head Final)"))
d.all.length.manip <- lmerTest::lmer(score ~ condition*length_difference + condition*animacy_contrast + 
                                       (1 +  length_difference + animacy_contrast || verb_lemma) + 
                                       (1 +  length_difference  + animacy_contrast || seed), REML=FALSE,
                        data = just.manip, control=lmerControl(optimizer="bobyqa"))

######################################################
# d$animacy_contrast = factor(d$animacy_contrast)
# d$pos_contrast = factor(d$pos_contrast)
###############################################

# checking for convergence

full <- lmer(score ~ length_difference + animacy_contrast + 
               (1 + length_difference + animacy_contrast | verb_lemma) + 
               (1 + length_difference + animacy_contrast | seed), REML=FALSE,
             data = d %>% filter(condition == "Unablated (Loose)"), control=lmerControl(optimizer="bobyqa"))

reduced <- lmer(score ~ length_difference +
                  (1 + length_difference + animacy_contrast | verb_lemma) + 
                  (1 | seed), REML=FALSE,
                data = d %>% filter(condition == "Unablated (Loose)"), control=lmerControl(optimizer="bobyqa"))

random_effects <- ranef(full)$verb_lemma

verb_effects <- rownames_to_column(ranef(full)$verb_lemma, var = "verb") %>%
  mutate(verb = fct_reorder(verb, animacy_contrast))

fcts <- sort(verb_effects$verb)

default_verb_plot <- verb_effects %>%
  ggplot(aes(verb, animacy_contrast)) +
  geom_col() +
  scale_y_continuous(limits = c(-0.3, 0.35), breaks = scales::pretty_breaks(6)) +
  theme_bw(base_size = 15, base_family = "Palatino") +
  theme(
    # axis.text.x = element_text(angle = 70, vjust = 0.6),
    axis.text.x = element_blank(),
    axis.text = element_text(color = "black"),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    plot.title = element_text(family="Inconsolata", size=12, hjust = 1)
  ) +
  labs(
    y="Animacy Effect",
    title = "default"
  )

## balanced

full_bal <- lmer(score ~ length_difference + animacy_contrast + 
                   (1 + length_difference + animacy_contrast | verb_lemma) + 
                   (1 + length_difference + animacy_contrast | seed), REML=FALSE,
                 data = d %>% filter(condition == "Balanced (Loose)"), control=lmerControl(optimizer="bobyqa"))

random_effects_bal <- ranef(full_bal)$verb_lemma
random_effects_bal

balanced_verb_plot <- rownames_to_column(ranef(full_bal)$verb_lemma, var = "verb") %>%
  mutate(verb = factor(verb, levels = fcts)) %>%
  ggplot(aes(verb, animacy_contrast)) +
  geom_col(fill = "#1b9e77") +
  scale_y_continuous(limits = c(-0.3, 0.35), breaks = scales::pretty_breaks(6)) +
  theme_bw(base_size = 15, base_family = "Palatino") +
  theme(
    # axis.text.x = element_text(angle = 70, vjust = 0.6),
    axis.text.x = element_blank(),
    axis.text = element_text(color = "black"),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    plot.title = element_text(family="Inconsolata", face="bold", size=12, hjust = 1)
  ) +
  labs(
    y="Animacy Effect",
    title = "balanced"
  )

# swapped datives

full_sd <- lmer(score ~ length_difference + animacy_contrast + 
                   (1 + length_difference + animacy_contrast | verb_lemma) + 
                   (1 + length_difference + animacy_contrast | seed), REML=FALSE,
                 data = d %>% filter(condition == "Swapped Datives"), control=lmerControl(optimizer="bobyqa"))

random_effects_sd <- ranef(full_sd)$verb_lemma
random_effects_sd
d %>% 
  filter(condition == "Swapped Datives") %>% 
  group_by(verb_lemma) %>% 
  summarise(n = n(), sd_animacy = sd(animacy_contrast), unique_animacy = n_distinct(animacy_contrast)) %>% 
  print(n = Inf)

swapped_verb_plot <- rownames_to_column(ranef(full_sd)$verb_lemma, var = "verb") %>%
  mutate(verb = factor(verb, levels = fcts)) %>%
  ggplot(aes(verb, animacy_contrast)) +
  geom_col(fill = "#d95f02") +
  scale_y_continuous(limits = c(-0.3, 0.35), breaks = scales::pretty_breaks(6)) +
  theme_bw(base_size = 15, base_family = "Palatino") +
  theme(
    axis.text.x = element_blank(),
    axis.text = element_text(color = "black"),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    plot.title = element_text(family="Inconsolata", face="bold", size=12, hjust = 1)
  ) +
  labs(
    y="Animacy Effect",
    title = "swapped-datives"
  )


## with no-datives

full_nod <- lmer(score ~ length_difference + animacy_contrast + 
               (1 + length_difference + animacy_contrast | verb_lemma) + 
               (1 + length_difference + animacy_contrast | seed), REML=FALSE,
             data = d %>% filter(condition == "No Datives"), control=lmerControl(optimizer="bobyqa"))

random_effects_nod <- ranef(full_nod)$verb_lemma

nodatives_verb_plot <- rownames_to_column(ranef(full_nod)$verb_lemma, var = "verb") %>%
  mutate(verb = factor(verb, levels = fcts)) %>%
  ggplot(aes(verb, animacy_contrast)) +
  geom_col(fill = "steelblue") +
  scale_y_continuous(limits = c(-0.3, 0.35), breaks = scales::pretty_breaks(6)) +
  theme_bw(base_size = 15, base_family = "Palatino") +
  theme(
    axis.text.x = element_text(angle = 70, vjust = 0.6),
    axis.text = element_text(color = "black"),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    plot.title = element_text(family="Inconsolata", face="bold", size=12, hjust = 1)
  ) +
  labs(
    y="Animacy Effect",
    title = "no datives"
  )

combined <- default_verb_plot / balanced_verb_plot / swapped_verb_plot / nodatives_verb_plot +
  plot_annotation(
    title = NULL,
    # theme = theme(plot.margin = margin(10, 10, 10, 10))
  ) +
  plot_layout(guides = "collect", axis_titles = "collect")

ggsave("paper/combined-verb-random-effects.svg", combined, height = 8.54, width = 13.77, dpi=300)
ggsave("paper/combined-verb-random-effects.pdf", combined, height = 8.54, width = 13.77, dpi=300, device=cairo_pdf)

anova(full, reduced)

#################
results_table <- data.frame(
  condition = character(),
  beta_animacy = numeric(),
  p_value = numeric(),
  significance = character(),
  stringsAsFactors = FALSE
)

# non_converging_conditions <- c("Unablated (Loose)", "Swapped Datives", "Short-first\n(No Ditransitives)")
# non_converging_conditions <- c("Long-first\n(No Ditransitives)")
# non_converging_conditions <- c("Random-first\n(No Ditransitives)", "No Datives", "Long-first\n(No Ditransitives)")
non_converging_conditions <- c("")

for (i in unique(d$condition)) {
  print(paste("Processing condition:", i))
  
  tryCatch({
    # if (i %in% non_converging_conditions) {
    #   l.full <- lmer(data = filter(d, condition == i),
    #                  score ~ 
    #                    length_difference + animacy_contrast +
    #                    (1 + length_difference + animacy_contrast || verb_lemma) + 
    #                    (1 + length_difference + animacy_contrast || seed),
    #                  REML = FALSE)
    #   
    #   l.reduced <- lmer(data = filter(d, condition == i),
    #                     score ~ 
    #                       length_difference +
    #                       (1 + length_difference + animacy_contrast || verb_lemma) + 
    #                       (1 + length_difference + animacy_contrast || seed),
    #                     REML = FALSE)
    # } else {
      l.full <- lmer(data = filter(d, condition == i),
                     score ~ 
                       length_difference + animacy_contrast +
                       (1 + length_difference + animacy_contrast | verb_lemma) + 
                       (1 + length_difference + animacy_contrast | seed),
                     REML = FALSE, control=lmerControl(optimizer="bobyqa"))
      
      l.reduced <- lmer(data = filter(d, condition == i),
                        score ~ 
                          length_difference +
                          (1 + length_difference + animacy_contrast | verb_lemma) + 
                          (1 + length_difference + animacy_contrast | seed),
                        REML = FALSE, control=lmerControl(optimizer="bobyqa"))
    # }
    a <- anova(l.full, l.reduced)
    a_tidy <- broom::tidy(a)
    
    p_value <- a_tidy$p.value[2] 
    
    coefs <- coef(summary(l.full))
    beta_animacy <- coefs["animacy_contrast", "Estimate"]
    
    sig_marker <- ifelse(p_value < 0.001, "***", ifelse(p_value < 0.01, "**", ifelse(p_value < 0.05, "*", "")))
    
    results_table <- rbind(results_table, 
                           data.frame(
                             condition = i,
                             beta_animacy = beta_animacy,
                             p_value = p_value,
                             significance = sig_marker
                           ))
    
  }, warning = function(e) {
    cat("Error in condition", i, ":", conditionMessage(e), "\n")
        results_table <<- rbind(results_table, 
                            data.frame(
                              condition = i,
                              beta_animacy = NA,
                              p_value = NA,
                              significance = "Error"
                            ))
  })
}

results_table$p_value_formatted <- sprintf("%.8f%s", results_table$p_value, results_table$significance)
print(results_table[, c("condition", "beta_animacy", "p_value_formatted")])
################
results_table_length <- data.frame(
  condition = character(),
  beta_length = numeric(),
  p_value = numeric(),
  significance = character(),
  stringsAsFactors = FALSE
)

# non_converging_conditions <- c("Random-first\n(No Ditransitives)", "Balanced (Loose)")
# non_converging_conditions <- c("No Datives", "Long-first\n(Head Final)")

for (i in unique(d$condition)) {
  print(paste("Processing condition:", i))
  
  tryCatch({
    # if (i %in% non_converging_conditions) {
    #   l.full <- lmer(data = filter(d, condition == i),
    #                  score ~ 
    #                    length_difference + animacy_contrast +
    #                    (1 + length_difference | verb_lemma) + 
    #                    (1 | seed),
    #                  REML = FALSE)
    #   
    #   l.reduced <- lmer(data = filter(d, condition == i),
    #                     score ~ 
    #                       animacy_contrast +
    #                       (1 + length_difference | verb_lemma) + 
    #                       (1 | seed),
    #                     REML = FALSE)
    # } else {
    l.full <- lmer(data = filter(d, condition == i),
                   score ~ 
                     length_difference + animacy_contrast +
                     (1 + length_difference + animacy_contrast | verb_lemma) + 
                     (1 + length_difference + animacy_contrast | seed),
                   REML = FALSE, control=lmerControl(optimizer="bobyqa"))
    
    l.reduced <- lmer(data = filter(d, condition == i),
                      score ~ 
                        animacy_contrast +
                        (1 + length_difference + animacy_contrast | verb_lemma) + 
                        (1 + length_difference + animacy_contrast | seed),
                      REML = FALSE, control=lmerControl(optimizer="bobyqa"))
    # }
    a <- anova(l.full, l.reduced)
    a_tidy <- broom::tidy(a)
    
    p_value <- a_tidy$p.value[2] 
    
    coefs <- coef(summary(l.full))
    beta_length <- coefs["length_difference", "Estimate"]
    
    sig_marker <- ifelse(p_value < 0.001, "***", ifelse(p_value < 0.01, "**", ifelse(p_value < 0.05, "*", "")))
    
    results_table_length <- rbind(results_table_length, 
                           data.frame(
                             condition = i,
                             beta_length = beta_length,
                             p_value = p_value,
                             significance = sig_marker
                           ))
    
  }, warning = function(e) {
    cat("Error in condition", i, ":", conditionMessage(e), "\n")
    results_table_length <<- rbind(results_table_length, 
                            data.frame(
                              condition = i,
                              beta_length = NA,
                              p_value = NA,
                              significance = "Error"
                            ))
  })
}

results_table_length$p_value_formatted <- sprintf("%.8f%s", results_table_length$p_value, results_table_length$significance)
print(results_table_length[, c("condition", "beta_length", "p_value_formatted")])


#########################
balance = filter(d, condition %in% c("Unablated (Loose)", "Balanced (Loose)"))
balance$condition = as.factor(as.character(balance$condition))
balance$condition = factor(balance$condition, 
                           levels=c("Unablated (Loose)", "Balanced (Loose)"))

l.balance = lmer(data=balance,
                          score ~ condition*length_difference + condition*animacy_contrast + 
                            (1 + length_difference + animacy_contrast |verb_lemma) + (1|seed),
                          REML=F,
                 control = lmerControl(optimizer = "bobyqa"))
l.reduced_length = lmer(data=balance,
                 score ~ 
                   condition*length_difference + condition*animacy_contrast - condition:length_difference +
                   (1 + length_difference + animacy_contrast |verb_lemma) + (1|seed),
                 REML=F,
                 control = lmerControl(optimizer = "bobyqa"))
l.reduced_animacy = lmer(data=balance,
                         score ~ 
                           condition*length_difference + condition*animacy_contrast - condition:animacy_contrast +
                           (1 + length_difference + animacy_contrast |verb_lemma) + (1|seed),
                         REML=F,
                         control = lmerControl(optimizer = "bobyqa"))
anova(l.balance, l.reduced_length)
anova(l.balance, l.reduced_animacy)



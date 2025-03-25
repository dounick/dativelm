library(tidyverse)
library(ggtext)

rawdata <- read_csv("analysis/all_data_strict.csv")

filter(rawdata, is.na(recipient_pos_spacy)) %>%
  select(sentence, recipient_pos, recipient_pos_spacy)

d <- rawdata %>%
  select(global_idx, recipient_pos, recipient_anim, theme_pos, theme_anim,
         strict_default_ratio21:strict_balanced_ratio63,
         length_difference,
         verb_lemma) %>%
  pivot_longer(
    cols = c(
      matches("strict_default_ratio\\d+"),
      matches("strict_balanced_ratio\\d+")
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
      levels = c("strict_default", "strict_balanced"),
      labels = c("Unablated", "Balanced")
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
                     (1 | seed),
                   REML = FALSE, control=lmerControl(optimizer="bobyqa"))
    
    l.reduced <- lmer(data = filter(d, condition == i),
                      score ~ 
                        length_difference +
                        (1 + length_difference + animacy_contrast | verb_lemma) + 
                        (1 | seed),
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
                     (1 | seed),
                   REML = FALSE, control=lmerControl(optimizer="bobyqa"))
    
    l.reduced <- lmer(data = filter(d, condition == i),
                      score ~ 
                        animacy_contrast +
                        (1 + length_difference + animacy_contrast | verb_lemma) + 
                        (1 | seed),
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



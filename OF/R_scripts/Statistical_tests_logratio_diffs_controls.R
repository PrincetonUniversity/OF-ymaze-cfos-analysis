library(rstatix)

# for visualization
library(ggpubr)
library(ggplot2)

dat <- read.table('../Output/Logratio_fraction_in_behavior_controls.txt', header = TRUE, sep = ",")

# preprocess data
dat$group <- as.factor(dat$group)
dat$mouse <- as.factor(dat$mouse)
dat$behavior <- as.factor(dat$behavior)

# visualize the data
bp <- ggplot(dat, aes(x=group, y=logratio, group=group)) + 
  geom_boxplot() + 
  facet_grid(. ~ behavior)
bp

## check assumptions for ANOVA
# identify outliers
dat %>%
  group_by(group, behavior) %>%
  identify_outliers(logratio) # there is one extreme outlier

# Shapiro-Wilk test for normality
shapirotest <- dat %>%
  group_by(group, behavior) %>%
  shapiro_test(logratio) 
shapirotest[shapirotest$p<0.05,] # two entries are significant --> nonparametric tests

ggqqplot(dat, "logratio", ggtheme = theme_bw()) +
  facet_grid(behavior ~ group, labeller = "label_both") # some outliers

#--- Kruskal-Wallis test ---#
for (i in c(1:8)){
  print(paste("Behavior: ",i))
  print(kruskal.test(logratio ~ group, data = dat[dat$behavior == i,]))
}
# behaviors 5 and 8 are significantly different between groups

# multiple comparison test
pairwise.wilcox.test(dat$logratio[dat$behavior == 5], dat$group[dat$behavior == 5],
                     p.adjust.method = "BH") # 1-2 (p < 0.01)

pairwise.wilcox.test(dat$logratio[dat$behavior == 8], dat$group[dat$behavior == 8],
                     p.adjust.method = "BH") # 1-2 (p < 0.01), 2-3 (p < 0.05)

# effect size
eff_size <- dat %>% group_by(behavior) %>% 
  wilcox_effsize(logratio ~ group)

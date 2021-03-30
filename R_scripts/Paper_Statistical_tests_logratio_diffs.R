library(rstatix)

# for visualization
library(ggpubr)
library(ggplot2)

dat <- read.table('/Users/bergeler/Documents/Mouse\ Behavior/Paper_Jess/Output/Logratio_fraction_in_behavior.txt', header = TRUE, sep = ",")

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
shapirotest[shapirotest$p<0.05,] # two entries are significant

ggqqplot(dat, "logratio", ggtheme = theme_bw()) +
  facet_grid(behavior ~ group, labeller = "label_both") # some outliers

# Check homogeneity of variance assumption of between-subject factor
dat %>%
  group_by(behavior) %>%
  levene_test(logratio ~ group) # no significant value

# Check homogeneity of covariances assumption
box_m(dat[, "logratio", drop = FALSE], dat$group) # homogeneity of covariances (p>0.001)

#--- Kruskal-Wallis test ---#
for (i in c(1:8)){
  print(paste("Behavior: ",i))
  print(kruskal.test(logratio ~ group, data = dat[dat$behavior == i,]))
}
# behaviors 3, 6 and 8 are significantly different between groups

# multiple comparison test
pairwise.wilcox.test(dat$logratio[dat$behavior == 3], dat$group[dat$behavior == 3],
                     p.adjust.method = "BH") # no significant results

pairwise.wilcox.test(dat$logratio[dat$behavior == 6], dat$group[dat$behavior == 6],
                     p.adjust.method = "BH") # 1-3 (p < 0.05),1-5 (p < 0.05)

pairwise.wilcox.test(dat$logratio[dat$behavior == 8], dat$group[dat$behavior == 8],
                     p.adjust.method = "BH") # 1-2 (p < 0.05),1-5 (p < 0.05)

# effect size
eff_size <- dat %>% group_by(behavior) %>% 
  wilcox_effsize(logratio ~ group)

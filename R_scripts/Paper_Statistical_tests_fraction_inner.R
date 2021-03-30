library(rstatix)

# for visualization
library(ggplot2)
library(ggpubr)

dat <- read.table('/Users/bergeler/Documents/Mouse\ Behavior/Paper_Jess/Output/Classical_measures.txt', header = TRUE, sep = ",")

# fraction in inner region
dat <- as.data.frame(dat[,c('day','group','mouse','fraction_inner')])
dat$group <- as.factor(dat$group)
dat$day <- as.factor(dat$day)
dat$mouse <- as.factor(dat$mouse)

## analyze and visualize the data
grp_stats <- dat %>%
  group_by(group, day) %>%
  get_summary_stats(fraction_inner, type = "median")

bp <- ggplot(dat, aes(x=group, y=fraction_inner, group=group)) + 
  geom_boxplot() + 
  facet_grid(. ~ day)
bp

# OR: 
bxp <- ggboxplot(
  dat, x = "day", y = "fraction_inner",
  color = "group", palette = "jco"
)
bxp

## check assumptions for ANOVA
# identify outliers
outliers <- dat %>%
  group_by(group, day) %>%
  identify_outliers(fraction_inner) 
# no extreme outliers

# Shapiro-Wilk test for normality
dat %>%
  group_by(group, day) %>%
  shapiro_test(fraction_inner)
# 1 significant results (day 1, group 1) --> Kruskal-Wallis test

# Visual check of normality
ggqqplot(dat, "fraction_inner", ggtheme = theme_bw()) +
  facet_grid(day ~ group, labeller = "label_both") # looks good 

# Check homogeneity of variance assumption of between-subject factor
dat %>%
  group_by(day) %>%
  levene_test(fraction_inner ~ group) # no significant results

# Check homogeneity of covariances assumption
box_m(dat[, "fraction_inner", drop = FALSE], dat$group) # homogeneity of covariances (p>0.001)

# sphericity does not need to be checked since we consider only 2 time points (levels)

# --- two-way mixed ANOVA ---#
res.aov <- anova_test(
  data = dat, dv = fraction_inner, wid = mouse,
  between = group, within = day
)
get_anova_table(res.aov) # no significant 2-way interaction
# statistically significant main effects of day and group

# Post-hoc tests
dat %>%
  pairwise_t_test(
    fraction_inner ~ day, paired = TRUE, 
    p.adjust.method = "bonferroni"
  ) # significant difference between days p < 0.0001

dat %>%
  pairwise_t_test(
    fraction_inner ~ group, 
    p.adjust.method = "bonferroni"
  ) # significant difference of group 1 and group 5 (p<0.05)

#--- Kruskal-Wallis test ---#
kruskal.test(fraction_inner ~ group, data = dat[dat$day == 1,]) # just significant
kruskal.test(fraction_inner ~ group, data = dat[dat$day == 2,]) # not significant

dat[dat$day == 1,] %>% kruskal_effsize(fraction_inner ~ group)

# multiple comparison test
pairwise.wilcox.test(dat$fraction_inner[dat$day == 1], dat$group[dat$day == 1],
                     p.adjust.method = "BH") # 1-5 (p < 0.05)

# effect size
wilcox_effsize(dat[dat$day == 1,],fraction_inner ~ group)
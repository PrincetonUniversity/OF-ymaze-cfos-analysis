library(rstatix)
library(car)
library(DescTools)

# for visualization
library(ggplot2)
library(ggpubr)

dat <- read.table('/Users/bergeler/Documents/Mouse\ Behavior/Paper_Jess/Output/Classical_measures.txt', header = TRUE, sep = ",")

# total distance traveled
dat <- as.data.frame(dat[,c('day','group','mouse','tot_distance')])
dat$group <- as.factor(dat$group)
dat$day <- as.factor(dat$day)
dat$mouse <- as.factor(dat$mouse)

## analyze and visualize the data
grp_stats <- dat %>%
  group_by(group, day) %>%
  get_summary_stats(tot_distance, type = "median")

bp <- ggplot(dat, aes(x=group, y=tot_distance, group=group)) + 
  geom_boxplot() + 
  facet_grid(. ~ day)
bp

# OR: 
bxp <- ggboxplot(
  dat, x = "day", y = "tot_distance",
  color = "group", palette = "jco"
)
bxp

## check assumptions for ANOVA
# identify outliers
outliers <- dat %>%
  group_by(group, day) %>%
  identify_outliers(tot_distance) 
# there are 2 extreme outliers (day 2, group 2, mouse 8; day 1, group 4, mouse 8) 
# --> we perform the test with and without the outliers

# create data set with no extreme outliers
outliers <- outliers[outliers$is.extreme,]
dat_no <- dat
for (i in 1:dim(outliers)[1]){
  day_sel <- outliers$day[i]
  group_sel <- outliers$group[i]
  mouse_sel <- outliers$mouse[i]
  dat_no <- dat_no[!(dat_no$day == day_sel & dat_no$group == group_sel & dat_no$mouse == mouse_sel),]
}

# Shapiro-Wilk test for normality
dat %>%
  group_by(group, day) %>%
  shapiro_test(tot_distance)
# 2 significant results (day 2, group 2; day 1, group 4)

dat_no %>%
  group_by(group, day) %>%
  shapiro_test(tot_distance)
# no significant results

# Visual check of normality
ggqqplot(dat, "tot_distance", ggtheme = theme_bw()) +
  facet_grid(day ~ group, labeller = "label_both") # looks good except 2 extreme outliers

ggqqplot(dat_no, "tot_distance", ggtheme = theme_bw()) +
  facet_grid(day ~ group, labeller = "label_both") # looks good

# Check homogeneity of variance assumption of between-subject factor
dat %>%
  group_by(day) %>%
  levene_test(tot_distance ~ group)
# no significant results

# Check homogeneity of covariances assumption
box_m(dat[, "tot_distance", drop = FALSE], dat$group) # homogeneity of covariances (p>0.001)

# sphericity does not need to be checked since we consider only 2 time points (levels)

# --- two-way mixed ANOVA ---#
res.aov <- anova_test(
  data = dat, dv = tot_distance, wid = mouse,
  between = group, within = day
)
get_anova_table(res.aov) # significant 2-way interaction
# main effect day is significant; interaction term is significant --> perform one-way ANOVAs
# RESULT: total distance traveled significantly different at different days
# F(1,47) = 146, p < 0.0001, eta2[g] = 0.52

# same analysis for data set without extreme outliers
res.aov <- anova_test(
  data = dat_no, dv = tot_distance, wid = mouse,
  between = group, within = day
)
get_anova_table(res.aov) #  main effect day is significant; interaction term is significant --> perform one-way ANOVAs

# Effect of group at each day
one.way <- dat %>%
  group_by(day) %>%
  anova_test(dv = tot_distance, wid = mouse, between = group) %>%
  get_anova_table() %>%
  adjust_pvalue(method = "bonferroni")
one.way
# significant result for day 2

# Pairwise comparisons between group levels
pwc <- dat %>%
  group_by(day) %>%
  pairwise_t_test(tot_distance ~ group, p.adjust.method = "bonferroni")
pwc
# significant results: 
# day 2, group 1 vs group 2 (p adj < 0.01)
# day 2, group 2 vs group 3 (p adj < 0.05)

# Effect of time at each level of group
one.way2 <- dat %>%
  group_by(group) %>%
  anova_test(dv = tot_distance, wid = mouse, within = day) %>%
  get_anova_table() %>%
  adjust_pvalue(method = "bonferroni")
one.way2
# all groups show significant difference between days except group 2

# effect size
dat %>%
  group_by(group) %>%
  cohens_d(tot_distance ~ day, var.equal = FALSE)

# --- 2 one-way ANOVA tests ---#
res.aov1 <- aov(tot_distance ~ group, data = dat[dat$day ==1,])
summary(res.aov1) # no significant differences

res.aov2 <- aov(tot_distance ~ group, data = dat[dat$day ==2,])
summary(res.aov2) # significant differences

res.aov2b <- dat[dat$day ==2,] %>% anova_test(tot_distance ~ group)
res.aov2b # RESULT: significant differences between groups on day 2
# F(4,47) = 5.04, p = 0.002, eta2[g] = 0.3

res.aov1_no <- aov(tot_distance ~ group, data = dat_no[dat_no$day ==1,])
summary(res.aov1_no) # no significant differences

res.aov2_no <- aov(tot_distance ~ group, data = dat_no[dat_no$day ==2,])
summary(res.aov2_no) # significant differences

# --- multiple comparison test --- #
# TukeyHSD
TukeyHSD(res.aov2) # 1-2 (p<0.01) and 2-3 (p<0.01)
TukeyHSD(res.aov2_no) # 1-2, 2-3, 2-5

# Dunnett test
DunnettTest(x=dat$tot_distance[dat$day == 2], g=dat$group[dat$day == 2]) # 1-2
DunnettTest(x=dat_no$tot_distance[dat_no$day == 2], g=dat_no$group[dat_no$day == 2]) # 1-2

# get median distance between total distance traveled for lobule VI and control
dist_day2_lobVI <- grp_stats$median[grp_stats$day == 2 & grp_stats$group == 2]
dist_day2_control <- grp_stats$median[grp_stats$day == 2 & grp_stats$group == 1]
diff <- dist_day2_lobVI - dist_day2_control

# --- check assumptions of ANOVA ---#
# 1. homogeneity of variance
plot(res.aov1, 1)
plot(res.aov2, 1)
leveneTest(tot_distance ~ group, data = dat[dat$day ==1,]) # n.s.
leveneTest(tot_distance ~ group, data = dat[dat$day ==2,]) # n.s.

plot(res.aov1_no, 1)
plot(res.aov2_no, 1)
leveneTest(tot_distance ~ group, data = dat_no[dat_no$day ==1,]) # n.s.
leveneTest(tot_distance ~ group, data = dat_no[dat_no$day ==2,]) # just significant (p = 0.04969)

# 2. normality
plot(res.aov1, 2)
plot(res.aov2, 2)
plot(res.aov1_no, 2)
plot(res.aov2_no, 2)

aov_residuals1 <- residuals(object = res.aov1)
shapiro.test(x = aov_residuals1) # n.s.
hist(aov_residuals1, main="Histogram of standardised residuals",xlab="Standardised residuals")

aov_residuals2 <- residuals(object = res.aov2)
shapiro.test(x = aov_residuals2) # n.s.
hist(aov_residuals2, main="Histogram of standardised residuals",xlab="Standardised residuals")

aov_residuals1_no <- residuals(object = res.aov1_no)
shapiro.test(x = aov_residuals1_no) # n.s.
hist(aov_residuals1_no, main="Histogram of standardised residuals",xlab="Standardised residuals")

aov_residuals2_no <- residuals(object = res.aov2_no)
shapiro.test(x = aov_residuals2_no) # n.s.
hist(aov_residuals2_no, main="Histogram of standardised residuals",xlab="Standardised residuals")

# --- Effect size ---#
dat %>%
  group_by(day) %>%
  cohens_d(tot_distance ~ group, var.equal = TRUE, comparisons = list(c("1", "2"), c("2", "3")))
# effect sizes (d values): 
# day 2, group 1 vs group 2: -2.26 (large)
# day 2, group 2 vs group 3: 1.72 (large)

#--- Kruskal-Wallis test ---#
kruskal.test(tot_distance ~ group, data = dat[dat$day == 1,]) # not significant
kruskal.test(tot_distance ~ group, data = dat[dat$day == 2,]) # significant

# multiple comparison test
pairwise.wilcox.test(dat$tot_distance[dat$day == 2], dat$group[dat$day == 2],
                     p.adjust.method = "BH") # 1-2 and 2-3

# effect size
wilcox_effsize(dat[dat$day == 2,],tot_distance ~ group)

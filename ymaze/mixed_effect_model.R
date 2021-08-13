# analyze Y-maze learning experiment

require(ggplot2)
require(GGally)
require(reshape2)
require(lme4)
require(compiler)
require(parallel)
require(boot)
require(lattice)
library(dplyr) 
library(forcats)
library(multcomp)
library(plotrix)

# load data
my_data <- read.table("/Users/bergeler/Documents/Mouse\ Behavior/Paper_Jess/OF-ymaze-cfos-analysis/ymaze/Allmice_modified.txt", sep="\t", header = TRUE)
my_data <- my_data[,c(2,5:18)]
my_data <- melt(my_data, id=c("Group","ID"))

# split variable names to separate day and session
my_data$variable
dat1 <- data.frame(do.call(rbind, strsplit(as.vector(my_data$variable), split = "\\.\\.s")))
names(dat1) <- c("Day","Session")
my_data <- cbind(my_data[c(1,2,4)],dat1)

# convert percent to fractions
my_data$value <- my_data$value/100

# add column with total trials
my_data$totals = 5

# convert predictor variables to factors
my_data <- within(my_data, {
  Group <- factor(Group)
  Session_factor <- factor(Session)
  Session <- as.numeric(Session)
})

# combine data from group CNO only (there is an additional white space)
my_data$Group <- my_data$Group %>% fct_collapse(AcuteCNOonly = c("AcuteCNOonly","AcuteCNOonly "))

# change order of factor levels for group
my_data$Group <- factor(my_data$Group, levels = c("AcuteCNOonly","AcuteCNOnCrusI","AcuteCNOnCrusILT","AcuteCNOnCrusIRT","AcuteCNOnLobVI"))

# create new column for mouse id such that the ids are unique
my_data$Mouse.ID <- with(my_data, interaction(Group, ID))

# check if there is one measurement for each session for each mouse
t = table(droplevels(my_data)$Mouse.ID)
any(t != 13)

# --- visualize data ---#
data_acq_day1 <- my_data[my_data$Day == "acqday1",]
data_acq_day2 <- my_data[my_data$Day == "acqday2",]
data_rev <- my_data[my_data$Day == "rev",]

# acquisition day 1 and 2
ggplot(data_acq_day1,aes(x = Session_factor,y = value,fill = Group)) +
  geom_boxplot()

ad1 <- data_acq_day1 %>% 
  group_by(Group,Session) %>% 
  summarise_at(
    vars(value),
    list(mean_frac = mean, sem_frac = std.error)
  )

ad2 <- data_acq_day2 %>% 
  group_by(Group,Session) %>% 
  summarise_at(
    vars(value),
    list(mean_frac = mean, sem_frac = std.error)
  )

ggplot(ad1,aes(x = Session,y = mean_frac, group = Group)) +
  geom_line(aes(color = Group)) + 
  geom_errorbar(data=ad1, mapping=aes(x=Session, ymin=mean_frac-sem_frac, ymax=mean_frac+sem_frac,color=Group), width = 0.1) +
  ylim(0,1)

ggplot(ad2,aes(x = Session,y = mean_frac, group = Group)) +
  geom_line(aes(color = Group)) + 
  geom_errorbar(data=ad2, mapping=aes(x=Session, ymin=mean_frac-sem_frac, ymax=mean_frac+sem_frac,color=Group), width = 0.1) +
  ylim(0,1)
# NOTE: looks different than the plot in the paper --> have animals been excluded from the analysis?

# reversal
ggplot(data_rev,aes(x = Session_factor,y = value,fill = Group)) +
  geom_boxplot()

rev <- data_rev %>% 
  group_by(Group,Session) %>% 
  summarise_at(
    vars(value),
    list(name = mean)
  )

ggplot(rev,aes(x = Session,y = name, group = Group)) +
  geom_line(aes(color = Group)) + 
  ylim(0,1)
# NOTE: looks a bit different than the plot in the paper

# --- acquisition day 1 ---#

## GLMM models
# session as factor
m1day1 <- glmer(value ~ Group + Session_factor + (1 | Mouse.ID), data = data_acq_day1,
           family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"),
           nAGQ = 10)
summary(m1day1, corr = FALSE)

m2day1 <- glmer(value ~ Group*Session_factor + (1 | Mouse.ID), data = data_acq_day1,
           family = binomial, weights = totals,control = glmerControl(optimizer = "bobyqa"),
           nAGQ = 50) # warnings!
summary(m2day1, corr = FALSE) # huge std error for bilateral crus I:session 4 due to quasi-complete separation!

# session as quantitative variable
m3day1 <- glmer(value ~ Group + Session + (1 | Mouse.ID), data = data_acq_day1,
                family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"),
                nAGQ = 10)
summary(m3day1, corr = FALSE)

# with random slope
m4day1 <- glmer(value ~ Group + Session + (1 + Session | Mouse.ID), data = data_acq_day1,
                family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"))
summary(m4day1, corr = FALSE)

## model selection

# LRT
anova(m2day1,m1day1,test="Chisq") # m2day1 has larger AIC and is not significantly better

drop1(m1day1,test="Chisq") # significant contribution of Group and Session_factor
drop1(m2day1,test="Chisq") # no significant change by adding interactions

AIC(m1day1) # 635
AIC(m2day1) # 659
AIC(m3day1) # 637
AIC(m4day1) # 934
# --> use model m1day1 (lowest AIC)

# plot simulated values using model fit
m = m1day1
sim <- simulate(m, nsim = 100)
obs <- aggregate(data_acq_day1$value, by = list(group = data_acq_day1$Group, session = data_acq_day1$Session), mean)

s_p <- lapply(sim, aggregate,
              by = list(group = data_acq_day1$Group, session = data_acq_day1$Session),
              mean)
s_df <- do.call(rbind, s_p)

ggplot() +
  geom_jitter(aes(y = x, x = group), data = s_df, 
              width = 0.2, height = 0, shape = 1, alpha = 1/2) +
  geom_point(aes(y = x, x = group), data = obs, 
             size = 4, color = "blue") +
  facet_wrap(~session) +
  labs(x = "Groups", y = "Predicted Probability") +
  theme(axis.text.x = element_text(angle = 90))

## Posthoc test 
summary(glht(m1day1, mcp(Group="Dunnett")))
# Estimate Std. Error z value Pr(>|z|)
# AcuteCNOnCrusI - AcuteCNOonly == 0     1.5429     0.7309   2.111    0.116
# AcuteCNOnCrusILT - AcuteCNOonly == 0   0.1789     0.4769   0.375    0.989
# AcuteCNOnCrusIRT - AcuteCNOonly == 0  -0.4780     0.4802  -0.995    0.731
# AcuteCNOnLobVI - AcuteCNOonly == 0    -0.8678     0.6112  -1.420    0.434

# --> no significant differences between the groups and CNO only for acquisition day 1

# --- acquisition day 2 ---#
## GLMM models

# session as factor
m1day2 <- glmer(value ~ Group + Session_factor + (1 | Mouse.ID), data = data_acq_day2,
                family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"),
                nAGQ = 10)
summary(m1day2, corr = FALSE)

m2day2 <- glmer(value ~ Group*Session_factor + (1 | Mouse.ID), data = data_acq_day2,
                family = binomial, weights = totals,control = glmerControl(optimizer = "bobyqa"),
                nAGQ = 50) # warnings!
summary(m2day2, corr = FALSE) # huge std errors due to quasi-complete separation!

# session as quantitative variable
m3day2 <- glmer(value ~ Group + Session + (1 | Mouse.ID), data = data_acq_day2,
                family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"),
                nAGQ = 10)
summary(m3day2, corr = FALSE)

# with random slope
m4day2 <- glmer(value ~ Group + Session + (1 + Session | Mouse.ID), data = data_acq_day2,
                family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"))
summary(m4day2, corr = FALSE)

m5day2 <- glmer(value ~ Group*Session + (1 | Mouse.ID), data = data_acq_day2,
                family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"),
                nAGQ = 10)
summary(m5day2, corr = FALSE)

## model selection

# LRT
anova(m2day2,m1day2,test="Chisq") # m2day2 has larger AIC and is not significantly better
anova(m5day2,m3day2,test="Chisq") # m5day2 has larger AIC and is not significantly better

AIC(m1day2) # 334
AIC(m2day2) # 348
AIC(m3day2) # 336
AIC(m4day2) # 485
AIC(m5day2) # 337
# --> use model m1day2

drop1(m1day2,test="Chisq") # significant contribution of Session, no significant contribution of Group

m1bday2 <- glmer(value ~ Session_factor + (1 | Mouse.ID), data = data_acq_day2,
                family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"),
                nAGQ = 10)
summary(m1bday2, corr = FALSE)
AIC(m1bday2) # 334
# --> best models: m1day2 and m1bday2 (with no main effect of groups!)

# plot simulated values using model fit
m = m1day2
sim <- simulate(m, nsim = 100)
obs <- aggregate(data_acq_day2$value, by = list(group = data_acq_day2$Group, session = data_acq_day2$Session), mean)

s_p <- lapply(sim, aggregate,
              by = list(group = data_acq_day2$Group, session = data_acq_day2$Session),
              mean)
s_df <- do.call(rbind, s_p)

ggplot() +
  geom_jitter(aes(y = x, x = group), data = s_df, 
              width = 0.2, height = 0, shape = 1, alpha = 1/2) +
  geom_point(aes(y = x, x = group), data = obs, 
             size = 4, color = "blue") +
  facet_wrap(~session) +
  labs(x = "Groups", y = "Predicted Probability") +
  theme(axis.text.x = element_text(angle = 90))
# --> model m1day2 fits data a lot better than m1bday2 and since they have a very similar AIC, we use m1day2

# Posthoc test 
summary(glht(m1day2, mcp(Group="Dunnett")))
# Estimate Std. Error z value Pr(>|z|)
# AcuteCNOnCrusI - AcuteCNOonly == 0     3.1940     1.5490   2.062    0.133
# AcuteCNOnCrusILT - AcuteCNOonly == 0   0.6742     0.7274   0.927    0.786
# AcuteCNOnCrusIRT - AcuteCNOonly == 0   0.3816     0.7185   0.531    0.963
# AcuteCNOnLobVI - AcuteCNOonly == 0    -0.5326     0.8736  -0.610    0.941

# --> no significant differences between groups for acquisition day 2

# --- reversal ---#

## GLMM models
# session as factor
m1 <- glmer(value ~ Group + Session_factor + (1 | Mouse.ID), data = data_rev,
            family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"),
            nAGQ = 10)
summary(m1, corr = FALSE)

m2 <- glmer(value ~ Group*Session_factor + (1 | Mouse.ID), data = data_rev,
            family = binomial, weights = totals,control = glmerControl(optimizer = "bobyqa"),
            nAGQ = 10)
summary(m2, corr = FALSE)

# session as quantitative variable
m3 <- glmer(value ~ Group + Session + (1 | Mouse.ID), data = data_rev,
            family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"),
            nAGQ = 10)
summary(m3, corr = FALSE)

# with random slope
m4 <- glmer(value ~ Group + Session + (1 + Session | Mouse.ID), data = data_rev,
            family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"))
summary(m4, corr = FALSE)

## model selection

# LRT
anova(m2,m1,test="Chisq") # m2 has larger AIC, but is significantly better

drop1(m2,test="Chisq") # significant contribution of interaction term
drop1(m1,test="Chisq") # significant contribution of Group and Session_factor

AIC(m1) # 803
AIC(m2) # 804
AIC(m3) # 814
AIC(m4) # 1053
# --> both model m1 and m2 seem to be good

# plot simulated values using model fit
m = m2
sim <- simulate(m, nsim = 100)
obs <- aggregate(data_rev$value, by = list(group = data_rev$Group, session = data_rev$Session), mean)

s_p <- lapply(sim, aggregate,
              by = list(group = data_rev$Group, session = data_rev$Session),
              mean)
s_df <- do.call(rbind, s_p)

ggplot() +
  geom_jitter(aes(y = x, x = group), data = s_df, 
              width = 0.2, height = 0, shape = 1, alpha = 1/2) +
  geom_point(aes(y = x, x = group), data = obs, 
             size = 4, color = "blue") +
  facet_wrap(~session) +
  labs(x = "Groups", y = "Predicted Probability") +
  theme(axis.text.x = element_text(angle = 90))
# model m2 gives better fit, as expected, but model m1 also looks okay

## Posthoc analysis 
summary(glht(m1, mcp(Group="Dunnett"))) 
# Estimate Std. Error z value Pr(>|z|)    
# AcuteCNOnCrusI - AcuteCNOonly == 0    -2.0417     0.8145  -2.507   0.0441 *  
# AcuteCNOnCrusILT - AcuteCNOonly == 0   0.1183     0.5518   0.214   0.9987    
# AcuteCNOnCrusIRT - AcuteCNOonly == 0  -0.9105     0.5563  -1.637   0.3042    
# AcuteCNOnLobVI - AcuteCNOonly == 0    -3.2609     0.7341  -4.442   <0.001 ***
# --> significant difference between bilateral crus I and CNO only, as well as between lobule VI and CNO only

# testing significant differences between groups for each session
data_rev$groupses <- interaction(data_rev$Group, data_rev$Session)
model_posthoc <- glmer(value ~ groupses + (1 | Mouse.ID), data = data_rev, 
                       family = binomial, weights = totals, control = glmerControl(optimizer = "bobyqa"),
                       nAGQ = 10)
summary(model_posthoc)
contrasts <- c("AcuteCNOnCrusI.1 - AcuteCNOonly.1 = 0",
               "AcuteCNOnCrusILT.1 - AcuteCNOonly.1 = 0",
               "AcuteCNOnCrusIRT.1 - AcuteCNOonly.1 = 0",
               "AcuteCNOnLobVI.1 - AcuteCNOonly.1 = 0",
               "AcuteCNOnCrusI.2 - AcuteCNOonly.2 = 0",
               "AcuteCNOnCrusILT.2 - AcuteCNOonly.2 = 0",
               "AcuteCNOnCrusIRT.2 - AcuteCNOonly.2 = 0",
               "AcuteCNOnLobVI.2 - AcuteCNOonly.2 = 0",
               "AcuteCNOnCrusI.3 - AcuteCNOonly.3 = 0",
               "AcuteCNOnCrusILT.3 - AcuteCNOonly.3 = 0",
               "AcuteCNOnCrusIRT.3 - AcuteCNOonly.3 = 0",
               "AcuteCNOnLobVI.3 - AcuteCNOonly.3 = 0",
               "AcuteCNOnCrusI.4 - AcuteCNOonly.4 = 0",
               "AcuteCNOnCrusILT.4 - AcuteCNOonly.4 = 0",
               "AcuteCNOnCrusIRT.4 - AcuteCNOonly.4 = 0",
               "AcuteCNOnLobVI.4 - AcuteCNOonly.4 = 0",
               "AcuteCNOnCrusI.5 - AcuteCNOonly.5 = 0",
               "AcuteCNOnCrusILT.5 - AcuteCNOonly.5 = 0",
               "AcuteCNOnCrusIRT.5 - AcuteCNOonly.5 = 0",
               "AcuteCNOnLobVI.5 - AcuteCNOonly.5 = 0")
H <- glht(model_posthoc, linfct = mcp(groupses = contrasts),test = adjusted("holm"))
summary(H) # warnings

# AcuteCNOnLobVI.3 - AcuteCNOonly.3 == 0   -2.93424    0.88577  -3.313  0.01499 *  
# AcuteCNOnLobVI.4 - AcuteCNOonly.4 == 0   -4.07403    0.89351  -4.560  < 0.001 ***
# AcuteCNOnLobVI.5 - AcuteCNOonly.5 == 0   -3.19499    0.86616  -3.689  0.00386 ** 
# --> significant differences between lobule VI compared to CNO only on session 3, 4 and 5

# plot simulated values using model fit
m = model_posthoc
sim <- simulate(m, nsim = 100)
obs <- aggregate(data_rev$value, by = list(group = data_rev$Group, session = data_rev$Session), mean)

s_p <- lapply(sim, aggregate,
              by = list(group = data_rev$Group, session = data_rev$Session),
              mean)
s_df <- do.call(rbind, s_p)

ggplot() +
  geom_jitter(aes(y = x, x = group), data = s_df, 
              width = 0.2, height = 0, shape = 1, alpha = 1/2) +
  geom_point(aes(y = x, x = group), data = obs, 
             size = 4, color = "blue") +
  facet_wrap(~session) +
  labs(x = "Groups", y = "Predicted Probability") +
  theme(axis.text.x = element_text(angle = 90))

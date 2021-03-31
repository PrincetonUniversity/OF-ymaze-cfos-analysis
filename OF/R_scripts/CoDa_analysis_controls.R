# CoDa analysis of fractions spent in each of 8 behaviors

require(data.table)
require(compositions)
require(npmv)
library(plyr)
library(rstatix)

# for visualization
require(ggplot2)
library(ggpubr)

# load data set
dat <- read.table("../Output/Mouse_behavior_data_set_controls.csv",header = TRUE, sep = ",")

dat <- within(dat,{
  group <- factor(group)
  mouse <- factor(mouse)
  day <- factor(day)
  class <- factor(class, levels = c("1","2","3","4","5","6","7","8"),
                  labels = c('slow explore','groom','fast explore','reared','turning walk','slow locomotion','medium locomotion','fast locomotion'))
})

# get number of zero counts
sum(dat$count == 0) # --> no zeros

# bring data into right format for later use
tab <- dcast(data = setDT(dat),formula = group + mouse + day ~ class,fun.aggregate = sum,value.var = "prob")
tab <- as.data.frame(tab)

# Make data compositional
dataset.compositional = acomp(tab[,4:11])

# calculate ilr coordinates
dataset.ilr <- ilr(dataset.compositional)

# make data sets with ilr coordinates
dat_ilr = cbind(tab[,1:3],dataset.ilr)

# change name of levels
dat_ilr$group <- revalue(dat_ilr$group, c("AcuteCNOonly2D"="CNO only","AcuteCNOnmcherry2D"="mCherry","AcuteVehicleonly2D"="Vehicle only"))

#--- MANOVA ---#
# 
ggboxplot(
  dat_ilr, x = "group", y = c("V1","V2","V3","V4","V5","V6","V7"), 
  merge = TRUE, palette = "jco"
)

dat1_ilr <- dat_ilr[dat_ilr$day == 1,]
dat2_ilr <- dat_ilr[dat_ilr$day == 2,]

# test multivariate normality
dat1_ilr %>%
  select(V1,V2,V3,V4,V5,V6,V7) %>%
  mshapiro_test()
# significant --> assumptions NOT satisfied --> use non-parametric test

dat2_ilr %>%
  select(V1,V2,V3,V4,V5,V6,V7) %>%
  mshapiro_test()
# significant --> assumptions NOT satisfied --> use non-parametric test

# non-parametric test 
# nonpartest(V1 | V2 | V3 | V4 | V5 | V6 | V7 ~ group, data = dat1_ilr) 
ssnonpartest(V1 | V2 | V3 | V4 | V5 | V6 | V7 ~ group, data = dat1_ilr, alpha = 0.05, factors.and.variables = TRUE)
# no significant difference 

# nonpartest(V1 | V2 | V3 | V4 | V5 | V6 | V7 ~ group, data = dat2_ilr)
ssnonpartest(V1 | V2 | V3 | V4 | V5 | V6 | V7 ~ group, data = dat2_ilr, alpha = 0.05, factors.and.variables = TRUE)
# significant difference between CNO only and Vehicle only, mCherry and Vehicle only, mCherry and CNO only  

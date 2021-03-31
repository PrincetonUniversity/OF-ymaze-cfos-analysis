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
dat <- read.table("../Output/Mouse_behavior_data_set.csv",header = TRUE, sep = ",")

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
dat_ilr$group <- revalue(dat_ilr$group, c("AcuteCNOnCrusILT2D"="CrusI_Left", 
                                            "AcuteCNOnCrusIRT2D"="CrusI_Right",
                                            "AcuteCNOnLobVI1D"="LobVI",
                                            "AcuteCNOonly2D"="CNO_only",
                                            "AcuteCNOnCrusI2D"="Bilateral_CrusI"))

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
# no significant difference between 2 groups

# nonpartest(V1 | V2 | V3 | V4 | V5 | V6 | V7 ~ group, data = dat2_ilr)
ssnonpartest(V1 | V2 | V3 | V4 | V5 | V6 | V7 ~ group, data = dat2_ilr, alpha = 0.05, factors.and.variables = TRUE)
# significant difference between LobVI and CNO_only and Bilateral_CrusI and LobVI 

# --- Visualization of the data ---#
# plot selected behaviors
tab <- within(tab,{
  group <- factor(group, levels = c("AcuteCNOnCrusI2D","AcuteCNOnCrusILT2D","AcuteCNOnCrusIRT2D",
                                    "AcuteCNOnLobVI1D","AcuteCNOonly2D"),
                  labels = c('Bilateral Crus I','Crus I Left','Crus I Right','Lobule VI','CNO Only'))
})
tab1 = tab[tab$day == 1,]
tab2 = tab[tab$day == 2,]

dataset1.compositional = acomp(tab1[,4:11])
dataset1.sel = acomp(dataset1.compositional,c("reared","medium locomotion","fast locomotion"))
plot(dataset1.sel,col = tab1$group)

dataset2.compositional = acomp(tab2[,4:11])
dataset2.sel = acomp(dataset2.compositional,c("reared","medium locomotion","fast locomotion"))
plot(dataset2.sel,col = tab2$group)

# plot two behaviors vs the rest
dataset1.sel_rest = acompmargin(dataset1.compositional,c("reared","medium locomotion"))
dataset2.sel_rest = acompmargin(dataset2.compositional,c("reared","medium locomotion"))

par(xpd=TRUE)
colors_sel = c(3,4,2,1)
plot(dataset1.sel_rest,col=colors_sel[as.numeric(tab1$group)],pch=as.numeric(tab1$group))
legend(1.2,1,legend=levels(tab1$group),xjust=1,col=colors_sel,pch=1:length(levels(tab1$group)))

plot(dataset2.sel_rest,col=colors_sel[as.numeric(tab2$group)],pch=as.numeric(tab2$group))
legend(1.2,1,legend=levels(tab2$group),xjust=1,col=colors_sel,pch=1:length(levels(tab2$group)))
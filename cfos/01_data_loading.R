# Load and Clean Data
library(readxl)

fp<-file.path
dp<-"data/original"

dreadds<-read.csv(fp(dp,"jess_cfos_dreadds_behavior - Sheet1.csv"), header=TRUE, na.strings=c("NA","N.A.","<NA>"))
clearmap<-read.csv(fp(dp,"jess_cfos_imaging_and_clearmap_params_20201125 - jess_cfos_imaging_and_clearmap_params_20201125.csv"), header=TRUE)
counts122<-as.data.frame(read_excel(fp(dp,"Jess_cfos_total_and_fractional_counts.xlsx"),sheet="total_122_regions"))

make_key<-function(dat){
    rownames(dat)<-paste(dat$batch,dat$brain,sep="-")
    dat
}
#unique identifier for each animal
dreadds<-make_key(dreadds)#[,-(10:619)])
clearmap<-make_key(clearmap)
counts122<-make_key(counts122)

#exclude animals in dreadds that were not in other data files
#sort all rows to be the same in all files
keep<-sort(Reduce(intersect,list(rownames(dreadds), rownames(clearmap), rownames(counts122))))
dreadds<-dreadds[keep,]
clearmap<-clearmap[keep,]
counts122<-as.matrix(counts122[keep,-(1:3)])

#misc data cleanup
dreadds$acq.day2..s2[dreadds$acq.day2..s2=="#NAME?"]<-NA
dreadds$acq.day2..s2<-as.numeric(dreadds$acq.day2..s2)
dreadds$Topaz.Number<-as.character(dreadds$Topaz.Number)

cm<-make_key(merge(clearmap,dreadds,by=c("brain","batch","condition")))
cm<-cm[keep,]
ctypes<-sapply(cm,mode)
cnumeric<-names(ctypes)[ctypes=="numeric"]
ccateg<-names(ctypes)[ctypes!="numeric"]
cm$batch<-factor(cm$batch)
cm$condition<-factor(cm$condition)

#drop regions that were zero in all animals
bad<-apply(counts122, 2, function(x){any(is.na(x)) || sd(x)<1e-6})
counts122<-counts122[,!bad]
pcounts122<-counts122/rowSums(counts122)

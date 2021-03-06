ROOT <- "e:/peter/bam/May2015"
ROOT2 <- "e:/peter/bam/Apr2016"

## Load required packages
library(mefa4)
library(RODBC)
library(maptools)
library(pbapply)
library(detect)

## Load functions kept in separate file
source("~/repos/bamanalytics/R/dataprocessing_functions.R")

### ABMI data processing

pcabmi <- read.csv(file.path(ROOT, "abmi", "birds.csv"))
ssabmi <- read.csv(file.path(ROOT, "abmi", "sitemetadata.csv"))

## Labels etc
## SK alpac sites to exclude (xy is hard to track down)
pcabmi <- droplevels(pcabmi[!grepl("ALPAC-SK", pcabmi$SITE_LABEL),])

tmp <- do.call(rbind, sapply(levels(pcabmi$SITE_LABEL), strsplit, "_"))
colnames(tmp) <- c("Protocol", "OnOffGrid", "DataProvider", "SiteLabel", "YYYY", "Visit", "SubType", "BPC")
tmp2 <- sapply(tmp[,"SiteLabel"], strsplit, "-")
tmp3 <- sapply(tmp2, function(z) if (length(z)==1) "ABMI" else z[2])
tmp4 <- sapply(tmp2, function(z) if (length(z)==1) z[1] else z[3])
tmp <- data.frame(tmp, ClosestABMISite=tmp4)
tmp$DataProvider <- as.factor(tmp3)
tmp$Label <- with(tmp, paste(OnOffGrid, DataProvider, SiteLabel, YYYY, Visit, "PC", BPC, sep="_"))
tmp$Label2 <- with(tmp, paste(OnOffGrid, DataProvider, SiteLabel, YYYY, Visit, sep="_"))
tmp$ClosestABMISite <- as.integer(as.character(tmp$ClosestABMISite))
tmp$lat <- ssabmi$PUBLIC_LATTITUDE[match(tmp$ClosestABMISite, ssabmi$SITE_ID)]
tmp$long <- ssabmi$PUBLIC_LONGITUDE[match(tmp$ClosestABMISite, ssabmi$SITE_ID)]
#tmp$NatReg <- ssabmi$NATURAL_REGIONS[match(tmp$ClosestABMISite, ssabmi$SITE_ID)]
#tmp$boreal <- tmp$NatReg %in% c(c("Boreal", "Canadian Shield", "Foothills", "Rocky Mountain"))

pcabmi <- data.frame(pcabmi, tmp[match(pcabmi$SITE_LABEL, rownames(tmp)),])

## PKEY table and proper date format
PKEY_abmi <- nonDuplicated(pcabmi, pcabmi$Label, TRUE)
tmp <- PKEY_abmi$ADATE
tmp <- sapply(as.character(tmp), strsplit, split="-")
for (i in 1:length(tmp)) {
    if (length(tmp[[i]])<3) {
        tmp[[i]] <- rep("99", 3)
    }
}
table(sapply(tmp, "[[", 2))
for (i in 1:length(tmp)) {
    tmp[[i]][2] <- switch(tmp[[i]][2],
        "May"=5, "Jun"=6, "Jul"=7, "Aug"=8, "99"=99)
}
tmp <- sapply(tmp, function(z) paste("20",z[3],"-",z[2],"-",z[1], sep=""))
tmp[tmp=="2099-99-99"] <- NA
PKEY_abmi$Date <- as.POSIXct(tmp, tz="America/Edmonton")

## TSSR
Coor <- as.matrix(cbind(as.numeric(PKEY_abmi$long),as.numeric(PKEY_abmi$lat)))
JL <- as.POSIXct(PKEY_abmi$Date, tz="America/Edmonton")
subset <- rowSums(is.na(Coor))==0 & !is.na(JL)
sr <- sunriset(Coor[subset,], JL[subset], direction="sunrise", POSIXct.out=FALSE) * 24
PKEY_abmi$srise_MDT <- NA
PKEY_abmi$srise_MDT[subset] <- sr

tmp <- strsplit(as.character(PKEY_abmi$TBB_START_TIME), ":")
id <- sapply(tmp,length)==2
tmp <- tmp[id]
tmp <- as.integer(sapply(tmp,"[[",1)) + as.integer(sapply(tmp,"[[",2))/60
PKEY_abmi$start_time <- NA
PKEY_abmi$start_time[id] <- tmp
PKEY_abmi$srise <- PKEY_abmi$srise_MDT
PKEY_abmi$TSSR <- (PKEY_abmi$start_time - PKEY_abmi$srise) / 24 # MDT offset is 0

## Julian day
PKEY_abmi$jan1 <- as.Date(paste(PKEY_abmi$YEAR, "-01-01", sep=""))
PKEY_abmi$JULIAN <- as.numeric(as.Date(PKEY_abmi$Date)) - as.numeric(PKEY_abmi$jan1) + 1
PKEY_abmi$JULIAN[PKEY_abmi$JULIAN > 365] <- NA
PKEY_abmi$JDAY <- PKEY_abmi$JULIAN / 365

if (FALSE) {

aa <- PKEY_abmi
CL <- rgb(210, 180, 140, alpha=0.25*255, max=255)

op <- par(mfrow=c(3,1))
boxplot(JULIAN~YEAR,aa, ylab="Julian day")
abline(h=seq(0, 360, by=30), col="grey")
text(rep(0.5, 12), seq(0, 360, by=30)+25, c("Jan","Feb","Mar","Apr","May","Jun",
    "Jul", "Aug","Sep","Oct","Nov","Dec"))
boxplot(JULIAN~YEAR,aa, add=TRUE, col=CL)
abline(h=mean(aa$JULIAN, na.rm=TRUE), col=2, lty=2, lwd=2)

boxplot(start_time~YEAR,aa, ylab="Start time (hours)")
abline(h=seq(0, 24, by=2), col="grey")
boxplot(start_time~YEAR,aa, add=TRUE, col=CL)
abline(h=mean(aa$start_time, na.rm=TRUE), col=2, lty=2, lwd=2)

plot(start_time ~ srise, aa, pch=19, col=CL,
    xlab="Sunrise time (24 hour clock)", ylab="Start time (24 hour clock)")
abline(0, 1)
for (i in c(1:10*2))
    abline(i, 1, col="grey")
abline(lm(start_time ~ srise, aa), col=2, lwd=2, lty=2)
box()
par(op)

## Check EMCLA

rownames(PKEY) <- PKEY$PKEY
i <- grepl("EMCLA", rownames(PKEY))
x <- droplevels(PKEY[i,])
hist(x$start_time)
hist(x$JDAY*365)

plot(x$JDAY*365, x$HOUR, col=CL, pch=19, type="n", main="EMCLA",
    ylab="Start time (24 hour clock)", xlab="Julian day")
abline(v=seq(0, 360, by=30), col="grey")
text(seq(0, 360, by=30)+17, rep(13, 12), c("Jan","Feb","Mar","Apr","May","Jun",
    "Jul", "Aug","Sep","Oct","Nov","Dec"))
abline(h=seq(0, 24, by=5), col="grey")
points(x$JDAY*365, x$HOUR, col=CL, pch=19)
}

## counts

load(file.path(ROOT2, "out",
    #paste0("data_package_2016-04-18.Rdata")))
#    paste0("data_package_2016-07-05.Rdata")))
    paste0("data_package_2016-12-01.Rdata")))

PCTBL_abmi <- pcabmi
levels(PCTBL_abmi$COMMON_NAME)[levels(PCTBL_abmi$COMMON_NAME) == "Black and White Warbler"] <- "Black-and-white Warbler"
compare.sets(TAX$English_Name, PCTBL_abmi$COMMON_NAME)
compare.sets(TAX$Scientific_Name, PCTBL_abmi$SCIENTIFIC_NAME)
setdiff(PCTBL_abmi$COMMON_NAME, TAX$English_Name)
setdiff(PCTBL_abmi$SCIENTIFIC_NAME, TAX$Scientific_Name)

PCTBL_abmi$SPECIES <- TAX$Species_ID[match(PCTBL_abmi$COMMON_NAME, TAX$English_Name)]
levels(PCTBL_abmi$SPECIES) <- c(levels(PCTBL_abmi$SPECIES), "NONE")
PCTBL_abmi$SPECIES[PCTBL_abmi$SPECIES == "TERN_UNI"] <- "NONE"
PCTBL_abmi$SPECIES <- droplevels(PCTBL_abmi$SPECIES)

##  2003-2008 values range 0-600; 2009-2015 values range 0-10 (minutes)
PCTBL_abmi$TBB_TIME_1ST_DETECTED <- as.character(PCTBL_abmi$TBB_TIME_1ST_DETECTED)
table(PCTBL_abmi$TBB_TIME_1ST_DETECTED,PCTBL_abmi$YEAR)
for (ii in 1:10) {
    PCTBL_abmi$TBB_TIME_1ST_DETECTED[PCTBL_abmi$TBB_TIME_1ST_DETECTED == as.character(ii) &
        PCTBL_abmi$YEAR >= 2009] <- as.character(ii * 60)
}
PCTBL_abmi$TBB_TIME_1ST_DETECTED[PCTBL_abmi$TBB_TIME_1ST_DETECTED %in%
    c("DNC", "NONE", "VNA")] <- NA
PCTBL_abmi$TBB_TIME_1ST_DETECTED <- as.numeric(as.character(PCTBL_abmi$TBB_TIME_1ST_DETECTED))
PCTBL_abmi$period1st <- as.numeric(cut(PCTBL_abmi$TBB_TIME_1ST_DETECTED, c(-1, 200, 400, 600)))

PCTBL_abmi <- PCTBL_abmi[PCTBL_abmi$TBB_INTERVAL_1 %in% c("0","1"),]
PCTBL_abmi <- PCTBL_abmi[PCTBL_abmi$TBB_INTERVAL_2 %in% c("0","1"),]
PCTBL_abmi <- PCTBL_abmi[PCTBL_abmi$TBB_INTERVAL_3 %in% c("0","1"),]
PCTBL_abmi$TBB_INTERVAL_1 <- as.integer(PCTBL_abmi$TBB_INTERVAL_1) - 1L
PCTBL_abmi$TBB_INTERVAL_2 <- as.integer(PCTBL_abmi$TBB_INTERVAL_2) - 1L
PCTBL_abmi$TBB_INTERVAL_3 <- as.integer(PCTBL_abmi$TBB_INTERVAL_3) - 1L

tmp <- col(matrix(0,nrow(PCTBL_abmi),3)) *
    PCTBL_abmi[,c("TBB_INTERVAL_1","TBB_INTERVAL_2","TBB_INTERVAL_3")]
tmp[tmp==0] <- NA
tmp <- cbind(999,tmp)
PCTBL_abmi$period123 <- apply(tmp, 1, min, na.rm=TRUE)
with(PCTBL_abmi, table(period1st, period123))
PCTBL_abmi$period1 <- pmin(PCTBL_abmi$period1st, PCTBL_abmi$period123)
with(PCTBL_abmi, table(period1st, period1))
with(PCTBL_abmi, table(period123, period1))


## Data package for new offsets
dat <- data.frame(PKEY[,c("PCODE","PKEY","SS","YEAR","TSSR","JDAY","JULIAN",
    "srise","start_time","MAXDUR","MAXDIS","METHOD","DURMETH","DISMETH","ROAD")],
    SS[match(PKEY$SS, rownames(SS)),c("TREE","TREE3","HAB_NALC1","HAB_NALC2",
    "BCR","JURS","SPRNG","DD51","X","Y")], NR=NA, LCC_combo=NA)
dat <- dat[dat$ROAD == 0,]
rownames(dat) <- dat$PKEY
ii <- intersect(dat$PKEY, levels(PCTBL$PKEY))
dat <- droplevels(dat[ii,])
summary(dat)
colSums(is.na(dat))
## sra and edr might have different NA patterns -- it is OK to exclude them later
#dat <- dat[rowSums(is.na(dat)) == 0,]
dat <- droplevels(dat)
dat$TSLS <- (dat$JULIAN - dat$SPRNG) / 365
dat$DD5 <- (dat$DD51 - 1600) / 1000
dat$DD51 <- NULL

## nat regions to filter grasslands
luf <- read.csv("~/repos/abmianalytics/lookup/sitemetadata.csv")
PKEY_abmi$NR <- luf$NATURAL_REGIONS[match(PKEY_abmi$ClosestABMISite, luf$SITE_ID)]
table(PKEY_abmi$NR)

dat2 <- with(PKEY_abmi, data.frame(
    PCODE="ABMI",
    PKEY=as.factor(Label),
    SS=as.factor(Label2),
    YEAR=YEAR,
    TSSR=TSSR,
    JDAY=JDAY,
    JULIAN=JULIAN,
    srise=srise,
    start_time=start_time,
    MAXDUR=10,
    MAXDIS=Inf,
    METHOD="ABMI:1",
    DURMETH="X",
    DISMETH="D",
    ROAD=0,
    TREE=NA,
    TREE3=NA,
    LCC_combo=NA,
    HAB_NALC1=NA,
    HAB_NALC2=NA,
    BCR=factor("6", levels(dat$BCR)),
    JURS=factor("AB", levels=levels(dat$JURS)),
    SPRNG=NA,
    X=long,
    Y=lat,
    TSLS=NA,
    DD5=NA,
    NR=NR))
rownames(dat2) <- dat2$PKEY
#write.csv(dat2, row.names=FALSE, file="ABMI-XY.csv")
ls_abmi <- read.csv("e:/peter/bam/May2015/ABMI_XY_JDStart_DD5.csv")
rownames(ls_abmi) <- ls_abmi$PKEY
ls_abmi <- ls_abmi[rownames(dat2),]
dat2$SPRNG <- ls_abmi$JSD_00_13
dat2$TSLS <- (dat2$JULIAN - dat2$SPRNG) / 365


## Oddities that should not happen:
PCTBL$dur <- as.character(PCTBL$dur)
PCTBL$dur[with(PCTBL, DURMETH=="A" & dur=="0-3")] <- "0-10"
# PCTBL$dur[with(PCTBL, DURMETH=="B" & dur=="5-8")] <- "0-5" -- fixed on proj summ
PCTBL$dur[with(PCTBL, DURMETH=="X" & dur=="10-10")] <- "6.66-10"
PCTBL$dur <- as.factor(PCTBL$dur)

PCTBL$dis <- as.character(PCTBL$dis)
PCTBL$dis[with(PCTBL, DISMETH=="B" & dis=="0-Inf")] <- "0-50" # best guess
PCTBL$dis[with(PCTBL, DISMETH=="C" & dis=="0-Inf")] <- "0-50" # best guess
PCTBL$dis[with(PCTBL, DISMETH=="F")] <- "0-100" # all kinds of weird stuff
PCTBL$dis[with(PCTBL, DISMETH=="I" & dis=="100-125")] <- "0-25"
PCTBL$dis[with(PCTBL, DISMETH=="I" & dis=="100-Inf")] <- "0-25" # best guess
#PCTBL$dis[with(PCTBL, DISMETH=="L" & dis=="150-Inf")] <- "100-150" # no >150
PCTBL$dis[with(PCTBL, DISMETH=="M" & dis=="0-Inf")] <- "150-Inf"
#PCTBL$dis[with(PCTBL, DISMETH=="T" & dis=="100-Inf")] <- "-" # no >100
PCTBL$dis[with(PCTBL, DISMETH=="U" & dis=="0-50")] <- "40-50"
PCTBL$dis[with(PCTBL, DISMETH=="U" & dis=="100-150")] <- "125-150"
PCTBL$dis[with(PCTBL, DISMETH=="U" & dis=="100-Inf")] <- "150-Inf"
PCTBL$dis[with(PCTBL, DISMETH=="U" & dis=="50-100")] <- "90-100"
PCTBL$dis[with(PCTBL, DISMETH=="U" & dis=="50-Inf")] <- "150-Inf"
PCTBL$dis[with(PCTBL, DISMETH=="W" & dis=="150-Inf")] <- "100-Inf"
PCTBL$dis[with(PCTBL, DISMETH=="W" & dis=="100-125")] <- "100-Inf"
PCTBL$dis <- as.factor(PCTBL$dis)

#PCTBL$dis <- droplevels(PCTBL$dis)
#PCTBL$dur <- droplevels(PCTBL$dur)

pc <- droplevels(PCTBL[PCTBL$PKEY %in% levels(dat$PKEY),])
levels(pc$PKEY) <- c(levels(pc$PKEY), setdiff(levels(dat$PKEY), levels(pc$PKEY)))

pc2 <- with(PCTBL_abmi, data.frame(
    PCODE="ABMI",
    PKEY=as.factor(Label),
    SS=as.factor(Label2),
    SPECIES=SPECIES,
    ABUND=1,
    dur=factor(period1),
    dis="0-Inf",
    DISMETH="D",
    DURMETH="X"))
levels(pc2$dur) <- c("0-3.33","3.33-6.66","6.66-10")

## this includes all (not only singing) species
#pc$SPECIES <- pc$SPECIES_ALL

## combine dat, dat2 and pc pc2
dat <- rbind(dat, dat2[,colnames(dat)])
cn <- intersect(colnames(pc), colnames(pc2))
pc <- rbind(pc[,cn], pc2[,cn])

durmat <- as.matrix(Xtab(~ DURMETH + dur, pc))
durmat[durmat > 0] <- 1
dismat <- as.matrix(Xtab(~ DISMETH + dis, pc))
dismat[dismat > 0] <- 1

ltdur <- arrange.intervals(durmat)
ltdis <- arrange.intervals(dismat)
## divide by 100
ltdis$end <- ltdis$end / 100

if (FALSE) {
pcc <- nonDuplicated(pc, PKEY, TRUE)
ii <- intersect(rownames(pcc), rownames(dat))
pkk <- dat[ii,]
pcc <- pcc[ii,]
table(pcc=droplevels(pcc$DISMET), pkk=droplevels(pkk$DISMET), useNA="a")
table(pcc=droplevels(pcc$DURMET), pkk=droplevels(pkk$DURMET), useNA="a")

}


save(dat2, pc2,
    file=file.path(ROOT, "out",
    paste0("abmi_data_package_", Sys.Date(), ".Rdata")))

save(dat, pc, ltdur, ltdis, TAX,
    file=file.path(ROOT, "out",
#    paste0("new_offset_data_package_", Sys.Date(), "-all-species.Rdata")))
    paste0("new_offset_data_package_", Sys.Date(), ".Rdata")))

save(SS, PKEY, PCTBL, TAX,
    file=file.path(ROOT, "out",
    paste0("data_package_", Sys.Date(), ".Rdata")))


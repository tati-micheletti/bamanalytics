mod_Hab <- list(
    . ~ . + HAB,
    . ~ . + HABTR)
mod_Road <- list(
    . ~ . + ROAD,
    . ~ . + ROAD + ROAD:isNF,
    . ~ . + ROAD + ROAD:isDev + ROAD:isWet + ROAD:isOpn)
mod_Hgt <- list(
    . ~ . + HGT,
    . ~ . + HGT + HGT2,
    . ~ . + HGT + HGT:isDM + HGT:isWet,
    . ~ . + HGT + HGT:isDec + HGT:isMix + HGT:isWet,
    . ~ . + HGT + HGT2 + HGT:isDM + HGT:isWet + HGT2:isDM + HGT2:isWet,
    . ~ . + HGT + HGT2 + HGT:isDec + HGT:isMix + HGT:isWet + HGT2:isDec + HGT2:isMix + HGT2:isWet,
    . ~ . + HGT05,
    . ~ . + HGT05 + HGT,
    . ~ . + HGT05 + HGT05:isDM + HGT05:isWet,
    . ~ . + HGT05 + HGT05:isDec + HGT05:isMix + HGT05:isWet,
    . ~ . + HGT05 + HGT + HGT05:isDM + HGT05:isWet + HGT:isDM + HGT:isWet,
    . ~ . + HGT05 + HGT + HGT05:isDec + HGT05:isMix + HGT05:isWet +
            HGT:isDec + HGT:isMix + HGT:isWet)
## 2001-2013
mod_Dist <- list(
    . ~ . + DTB, # 10 yr post disturbance (loss or fire combined)
    . ~ . + BRN + LSS, # 10 yr post disturbance (loss or fire separate)
#    . ~ . + ALS + BRN, # constant disturbance and 10yr post fire
    . ~ . + YSD, # linear, combined
    . ~ . + YSF + YSL) # linear, separate
mod_Wet <- list(
    . ~ . + CTI,
    . ~ . + CTI + CTI2,
    . ~ . + SLP,
    . ~ . + SLP + SLP2)
mod_Climate_1 <- list(
    . ~ . + CMIJJA + DD0 + DD5 + EMT + TD + DD02 + DD52,
    . ~ . + CMI + DD0 + DD5 + EMT + TD + DD02 + DD52,
    . ~ . + CMI + CMIJJA + DD0 + MSP + TD + DD02,
    . ~ . + CMI + CMIJJA + DD5 + MSP + TD + DD52,
    . ~ . + CMIJJA + DD0 + DD5 + EMT + TD + MSP + DD02 + DD52,
    . ~ . + CMI + DD0 + DD5 + EMT + TD + MSP + DD02 + DD52,
    . ~ . + CMI + CMIJJA + DD0 + MSP + TD + EMT + DD02,
    . ~ . + CMI + CMIJJA + DD5 + MSP + TD + EMT + DD52)
mod_Climate_2 <- list(
    . ~ . + CMIJJA + DD0 + DD5 + EMT + MSP + DD02 + DD52 + CMIJJA2 +
        CMIJJA:DD0 + CMIJJA:DD5 + EMT:MSP,
    . ~ . + CMI + DD0 + DD5 + EMT + MSP + DD02 + DD52 + CMI2 +
        CMI:DD0 + CMI:DD5 + EMT:MSP,
    . ~ . + CMI + CMIJJA + DD0 + MSP + TD + DD02 + CMI2 + CMIJJA2 +
        CMI:DD0 + CMIJJA:DD0 + MSP:TD,
    . ~ . + CMI + CMIJJA + DD5 + MSP + TD + DD52 + CMI2 + CMIJJA2 +
        CMI:DD5 + CMIJJA:DD5 + MSP:TD,
    . ~ . + CMIJJA + DD0 + DD5 + EMT + TD + MSP + DD02 + DD52 + CMIJJA2 +
        CMIJJA:DD0 + CMIJJA:DD5 + MSP:TD + MSP:EMT,
    . ~ . + CMI + DD0 + DD5 + EMT + TD + MSP + DD02 + DD52 + CMI2 +
        CMI:DD0 + CMI:DD5 + MSP:TD + MSP:EMT,
    . ~ . + CMI + CMIJJA + DD0 + MSP + TD + EMT + DD02 + CMI2 + CMIJJA2 +
        CMI:DD0 + CMIJJA:DD0 + MSP:TD + MSP:EMT,
    . ~ . + CMI + CMIJJA + DD5 + MSP + TD + EMT + DD52 + CMI2 + CMIJJA2 +
        CMI:DD5 + CMIJJA:DD5 + MSP:TD + MSP:EMT)
mod_Climate_3 <- list(
    . ~ . + CMI + CMIJJA + DD0 + DD5 + EMT + MSP + TD +
        CMI2 + CMIJJA2 + DD02 + DD52 + EMT2 + MSP2 + TD2 +
        CMI:CMIJJA + CMI:DD0 + CMI:DD5 + CMI:EMT + CMI:MSP + CMI:TD +
        CMIJJA:DD0 + CMIJJA:DD5 + CMIJJA:EMT + CMIJJA:MSP + CMIJJA:TD +
        DD0:DD5 + DD0:EMT + DD0:MSP + DD0:TD +
        DD5:EMT + DD5:MSP + DD5:TD +
        EMT:MSP + EMT:TD,
        MSP:TD)
mod_Year <- list(
    . ~ . + YR)

mods <- list(
    Hab=mod_Hab,
    Road=mod_Road,
    Hgt=mod_Hgt,
    Dist=mod_Dist,
    Wet=mod_Wet,
    Clim=mod_Climate_2,
    Year=mod_Year)

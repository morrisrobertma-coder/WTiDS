#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 00_imd_data_processing.R
# Purpose of Script: Organise data for project 'Real-Time Monitoring
# of Local Authority Socioeconomic Position and Deprivation Risk in the UK'
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())

#~~~~~~~~~~~~~~~~~~~~~~~~~
# Initialization
#~~~~~~~~~~~~~~~~~~~~~~~~~
# packages
library("readxl")
library(data.table)

# paths
inp_path_imd <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/00_imd/")
inp_path_geo <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_geo/")
out_path <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_clean/")

# imd file names (same as when downloaded from gov.uk)
file_imd_2025 <- c("File_1_IoD2025_Index_of_Multiple_Deprivation.xlsx")
file_imd_2019 <- c("File_1_-_IMD2019_Index_of_Multiple_Deprivation.xlsx")
file_imd_2015 <- c("File_1_ID_2015_Index_of_Multiple_Deprivation.xlsx")
file_imd_2010 <- c("1871524.xls")
file_imd_2007 <- c("IMD 2007 for DCLG 4 dec.xls")

# postcode mapping
file_geo <- c("geo_map_clean.csv")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Geographic Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dt_geo <- as.data.table(read.csv(paste0(inp_path_geo, file_geo)))

# cut down to unique lsoas
dt_geo_cut <- dt_geo[,.(lsoa01, lsoa11, lsoa21)]
dt_geo_cut <- unique(dt_geo_cut)
gc()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# IMD Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### 2025 - 33755 observations
dt_25 <- as.data.table(read_excel(paste0(inp_path_imd,file_imd_2025), sheet = "IMD25"))
colnames(dt_25) <- c("lsoa_code","lsoa_name","lad_code","lad_name","imd_rank_25","imd_decile_25")
dt_25 <- dt_25[order(imd_rank_25)]

### 2019 - 32844 observations
dt_19 <- as.data.table(read_excel(paste0(inp_path_imd, file_imd_2019), sheet = "IMD2019"))
colnames(dt_19) <- c("lsoa_code","lsoa_name","lad_code","lad_name","imd_rank_19","imd_decile_19")
dt_19 <- dt_19[order(imd_rank_19)]

### 2015 - 32844 observations
dt_15 <- as.data.table(read_excel(paste0(inp_path_imd, file_imd_2015), sheet = "IMD 2015"))
colnames(dt_15) <- c("lsoa_code","lsoa_name","lad_code","lad_name","imd_rank_15","imd_decile_15")
dt_15 <- dt_15[order(imd_rank_15)]

### 2010 - 32482 observations
dt_10 <- as.data.table(read_excel(paste0(inp_path_imd, file_imd_2010), sheet = "IMD 2010"))
colnames(dt_10) <- c("lsoa_code","la_code","la_name","gor_code","gor_name","imd_score_10","imd_rank_10")
dt_10 <- dt_10[order(imd_rank_10)]

### 2007 - 32482 observations
dt_07 <- as.data.table(read_excel(paste0(inp_path_imd, file_imd_2007), sheet = "IMD 2007"))
colnames(dt_07) <- c("lsoa_code","la_code","la_name","gor_code","gor_name","imd_score_07","imd_rank_07")
dt_07 <- dt_07[order(imd_rank_07)]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# IMD Data: Clean and Merge
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate decile columns
dt_07 <- dt_07[, imd_decile_07 := ceiling(.I / (.N / 10))]
dt_10 <- dt_10[, imd_decile_10 := ceiling(.I / (.N / 10))]

# Drop additional columns from historic data
dt_10 <- dt_10[,c("la_code", "gor_code", "gor_name", "imd_score_10") := NULL]
dt_07 <- dt_07[,c("la_code", "gor_code", "gor_name", "imd_score_07") := NULL]

#~~~~~~~~~~~~~~~~~~~~~~~~~
# Merge Geographic Data
#~~~~~~~~~~~~~~~~~~~~~~~~~
### 2025 - LSOA21
dt_25 <- merge(dt_25,
               unique(dt_geo_cut[,.(lsoa11, lsoa21)]),
               by.x = 'lsoa_code',
               by.y = 'lsoa21',
               all.x = T)

### 2010 - LSOA01
dt_10 <- merge(dt_10,
               unique(dt_geo_cut[,.(lsoa01, lsoa11)]),
               by.x = "lsoa_code",
               by.y = "lsoa01",
               all.x = T)

### 2007 -  LSOA01
dt_07 <- merge(dt_07,
               unique(dt_geo_cut[,.(lsoa01, lsoa11)]),
               by.x = "lsoa_code",
               by.y = "lsoa01",
               all.x = T)

#~~~~~~~~~~~~~~~~~~~~~~~~~
# Adjust Ranking
#~~~~~~~~~~~~~~~~~~~~~~~~~
## Many to one mapping of LSOA codes. Adjust ranks for 2025, 2010 and 2007
dt_25 <- dt_25[, lsoa_code := lsoa11][,c("lsoa11") := NULL]
dt_25 <- dt_25[, imd_rank_25 := mean(imd_rank_25), by = lsoa_code]
dt_25 <- unique(dt_25, by = c("lsoa_code","imd_rank_25"))

dt_10 <- dt_10[, lsoa_code := lsoa11][,c("lsoa11") := NULL]
dt_10 <- dt_10[, imd_rank_10 := mean(imd_rank_10), by = lsoa_code]
dt_10 <- unique(dt_10, by = c("lsoa_code","imd_rank_10"))

dt_07 <- dt_07[, lsoa_code := lsoa11][,c("lsoa11") := NULL]
dt_07 <- dt_07[, imd_rank_07 := mean(imd_rank_07), by = lsoa_code]
dt_07 <- unique(dt_07, by = c("lsoa_code","imd_rank_07"))

#~~~~~~~~~~~~~~~~~~~~~~~~~
# Merge Data
#~~~~~~~~~~~~~~~~~~~~~~~~~
dt_imd <- merge(dt_25,
                dt_19[,.(lsoa_code, imd_rank_19, imd_decile_19)],
                by = 'lsoa_code',
                all = T)

dt_imd <- merge(dt_imd,
                dt_15[,.(lsoa_code, imd_rank_15, imd_decile_15)],
                by = 'lsoa_code',
                all = T)

dt_imd <- merge(dt_imd,
                dt_10[,.(lsoa_code, imd_rank_10, imd_decile_10)],
                by = "lsoa_code",
                all = T)

dt_imd <- merge(dt_imd,
                dt_07[,.(lsoa_code, imd_rank_07, imd_decile_07)],
                by = "lsoa_code",
                all = T)

# Clean
rm(list = c("dt_25","dt_19","dt_15","dt_10","dt_07"))
gc()

#~~~~~~~~~~~~~~~~~~~~~~~~~
# IMD Data: Order & Calculations
#~~~~~~~~~~~~~~~~~~~~~~~~~
# Drop rows containing NAs
### Reason: Some LSOAs are newly created or dropped in subsequent years.
###         Removing allows for consistent comparison across years
dt_imd <- dt_imd[!(is.na(lad_name))]
dt_imd <- dt_imd[!(is.na(imd_rank_07))]

# Order by rank 25
dt_imd <- dt_imd[order(imd_rank_25)]

# Calculate rank change relative to 2025
dt_imd <- dt_imd[, delta_5y := imd_rank_25 - imd_rank_19][
  , delta_10y := imd_rank_25 - imd_rank_15][
    , delta_15y := imd_rank_25 - imd_rank_10][
      , delta_18y := imd_rank_25 - imd_rank_07]

# Calculate rank change from previous IMD calc
dt_imd <- dt_imd[, delta_25_19 := imd_rank_25 - imd_rank_19][
  , delta_19_15 := imd_rank_19 - imd_rank_15][
    , delta_15_10 := imd_rank_15 - imd_rank_10][
      , delta_10_07 := imd_rank_10 - imd_rank_07]

# Calculate decile shift relative to 2025 
dt_imd <- dt_imd[, delta_decile_5y := imd_decile_25 - imd_decile_19][
  , delta_decile_10y := imd_decile_25 - imd_decile_15][
    , delta_decile_15y := imd_decile_25 - imd_decile_10][
      , delta_decile_18y := imd_decile_25 - imd_decile_07]

# Calculate decile shift from previous IMD calc
dt_imd <- dt_imd[, delta_decile_25_19 := imd_decile_25 - imd_decile_19][
  , delta_decile_19_15 := imd_decile_19 - imd_decile_15][
    , delta_decile_15_10 := imd_decile_15 - imd_decile_10][
      , delta_decile_10_07 := imd_decile_10 - imd_decile_07]

# Migration Flags
# Delta to Decile - negative values if area became more deprived
dt_imd <- dt_imd[, dep_flag_5y := ifelse(delta_decile_5y < 0, 1, 0)]

#~~~~~~~~~~~~~~~~~~~~~~~~~
# IMD Data: Export
#~~~~~~~~~~~~~~~~~~~~~~~~~
# Ensure unique entries - 32844 observations
dt_imd <- unique(dt_imd)

# Export
write.csv(dt_imd, file = paste0(out_path, "00_imd_data_clean.csv"))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clean 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())

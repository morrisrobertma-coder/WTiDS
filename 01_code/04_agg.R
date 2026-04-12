#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 04_agg.R
# Purpose of Script: Import all clean data, aggregate where necessary and 
#                    perform EDA for 'Real-Time Monitoring of Local Authority 
#                    Socioeconomic Position and Deprivation Risk in the UK'
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())

#~~~~~~~~~~~~~~~~~~~~~~~~~
# Initialization
#~~~~~~~~~~~~~~~~~~~~~~~~~
# packages
library(data.table)

# paths
inp_path_geo <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_geo/")
inp_clean <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_clean/")
out_path <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_clean/")

# files
file_geo <- c("geo_map_clean.csv")
file_imd <- c("00_imd_data_clean.csv")
file_digi <- c("01_digi_clean.csv")
file_energy <- c("02_energy_clean.csv")
file_trans <- c("03_transport_clean.csv")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Import Data 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Geographic Data
dt_geo <- as.data.table(read.csv(paste0(inp_path_geo,file_geo)))

# IMD Data
dt_imd <- as.data.table(read.csv(paste0(inp_clean, file_imd), row.names = 1))

# Digital 
dt_digi <- as.data.table(read.csv(paste0(inp_clean, file_digi), row.names = 1))

# Energy
dt_energy <- as.data.table(read.csv(paste0(inp_clean, file_energy), row.names = 1))

# Transport
dt_trans <- as.data.table(read.csv(paste0(inp_clean, file_trans), row.names = 1))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LSOA Code Check
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# IMD data - currently lsoa11
sum(dt_imd$lsoa_code %in% dt_geo$lsoa01)
sum(dt_imd$lsoa_code %in% dt_geo$lsoa11)
sum(dt_imd$lsoa_code %in% dt_geo$lsoa21)

# Digi - currently lsoa21
sum(dt_digi$lsoa_code %in% dt_geo$lsoa01)
sum(dt_digi$lsoa_code %in% dt_geo$lsoa11)
sum(dt_digi$lsoa_code %in% dt_geo$lsoa21)

# Energy - currently lsoa21
sum(dt_energy$lsoa_code %in% dt_geo$lsoa01)
sum(dt_energy$lsoa_code %in% dt_geo$lsoa11)
sum(dt_energy$lsoa_code %in% dt_geo$lsoa21)

# Transport - currently lsoa21
sum(dt_trans$lsoa_code %in% dt_geo$lsoa01)
sum(dt_trans$lsoa_code %in% dt_geo$lsoa11)
sum(dt_trans$lsoa_code %in% dt_geo$lsoa21)

# Remap IMD Data to LSOA21
dt_imd <- merge(dt_imd,
                unique(dt_geo[,.(lsoa11, lsoa21)]),
                by.x = "lsoa_code",
                by.y = "lsoa11",
                all.x = T)

dt_imd <- dt_imd[, lsoa_code := lsoa21][, lsoa21 := NULL]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# IMD Data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Important:
# Rank - 1 = Most Deprived
# Delta Rank Positive = Became more affluent
# Delta Rank Negative = Become more deprived
# Delta Decile Positive = Became more affluent
# Delta Decile Negative = Become more deprived

# Distribution of rank delta
summary(dt_imd$delta_decile_5y)

# Isolate LSOAs with greatest 5y decline
dt_dep <- dt_imd[delta_decile_5y %in% c(-5,-4)]

# Isolate LSOAs with greatest decline in London
london_boroughs <- c("City of London","Westminster","Kensington and Chelsea",
                     "Hammersmith and Fulham","Wandsworth","Lambeth",
                     "Southwark","Tower Hamlets","Hackney","Camden",
                     "Brent","Ealing","Hounslow","Richmond upon Thames",
                     "Kingston upon Thames","Merton","Sutton",
                     "Croydon","Bromley","Lewisham","Greenwich",
                     "Bexley","Havering","Barking and Dagenham",
                     "Redbridge","Newham","Waltham Forest",
                     "Haringey","Enfield","Barnet","Harrow",
                     "Hillingdon")

dt_london <- dt_imd[lad_name %in% london_boroughs]
dt_london_dep <- dt_london[delta_decile_5y %in% c(-5,-4, -3)]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Digital Data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Remove postcodes without full coverage
dt_digi_agg <- dt_digi[(!is.na(sfbb_availaibility_2025) & !is.na(sfbb_availaibility_2019))]
dt_digi_agg <- dt_digi_agg[order(lsoa_code)]

# Cut down data to relevant columns
dt_digi_agg <- dt_digi_agg[,':='(postcode_space = NULL, postcode = NULL,
                                 gigabit_availability_2025 = NULL)]

# Derived Columns - delta columns
comp_2025 <- grep("_2025", colnames(dt_digi_agg), value = TRUE)
comp_cols <- sub("_2025$","",comp_2025)

for (col in comp_2025){
  
  base <- sub("_2025$","",col)
  col_19 <- sub("_2025$","_2019",col)

  dt_digi_agg <- dt_digi_agg[, (paste0("delta_",base)) := get(col) - get(col_19)]
    
}

# Aggregate mean deltas
cols_delta <- grep("delta_", colnames(dt_digi_agg), value = TRUE)
cols_delta_all <- c("lsoa_code",cols_delta)

### Cut down data
dt_digi_agg_cut <- dt_digi_agg[, ..cols_delta_all]

### Find mean
dt_digi_agg_cut <- dt_digi_agg_cut[, lapply(.SD, mean, na.rm = TRUE),
                                   by = "lsoa_code", .SDcols = cols_delta] 

### Round mean
dt_digi_agg_cut <- dt_digi_agg_cut[, lapply(.SD, round, 2),
                                   by = "lsoa_code", .SDcols = cols_delta] 

# Rename
cols_delta <- grep("delta", colnames(dt_digi_agg_cut), value = TRUE)
cols_delta_mean <- paste0("mean_", cols_delta)
setnames(dt_digi_agg_cut, cols_delta, cols_delta_mean)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Energy Data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Initially cut to 2025 and 2019 timeslices
cols_2025 <- grep("_2025", colnames(dt_energy), value = TRUE)
cols_2019 <- grep("_2019", colnames(dt_energy), value = TRUE)
cols_extract <- c("lsoa_code", cols_2025, cols_2019)

dt_energy_agg <- copy(dt_energy[, ..cols_extract])

for (col in cols_2025){
  
  col_2019 <- gsub("_2025","_2019", col)
  col_delta <- paste0("delta_", gsub("_2025", "", col))
  
  dt_energy_agg <- dt_energy_agg[, (col_delta) := get(col) - get(col_2019)]
  
}

# cut down data
cols_delta <- grep("delta", colnames(dt_energy_agg), value = TRUE)
cols_delta_all <- c("lsoa_code", cols_delta)

dt_energy_agg_cut <- dt_energy_agg[, ..cols_delta_all]

# aggregate per lsoa (nearly complete)
dt_energy_agg_cut <- dt_energy_agg_cut[, lapply(.SD, mean, na.rm= TRUE),
                                       by = "lsoa_code",
                                       .SDcols = cols_delta]

# Rename columns
cols_mean <- paste0("mean_", cols_delta)
setnames(dt_energy_agg_cut, old = cols_delta, new = cols_mean)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Transport Data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Delta columns - entry/exit
dt_trans_agg <- copy(dt_trans)[,':='(delta_entry_1y = entrytapcount_2025 - entrytapcount_2024,
                                     delta_entry_2y = entrytapcount_2024 - entrytapcount_2023,
                                     delta_entry_3y = entrytapcount_2023 - entrytapcount_2022,
                                     delta_entry_4y = entrytapcount_2022 - entrytapcount_2021,
                                     delta_entry_5y = entrytapcount_2021 - entrytapcount_2020,
                                     delta_entry_6y = entrytapcount_2020 - entrytapcount_2019,
                                     delta_exit_1y = exittapcount_2025 - exittapcount_2024,
                                     delta_exit_2y = exittapcount_2024 - exittapcount_2023,
                                     delta_exit_3y = exittapcount_2023 - exittapcount_2022,
                                     delta_exit_4y = exittapcount_2022 - exittapcount_2021,
                                     delta_exit_5y = exittapcount_2021 - exittapcount_2020,
                                     delta_exit_6y = exittapcount_2020 - exittapcount_2019,
                                     delta_entry_all = entrytapcount_2025 - entrytapcount_2019,
                                     delta_exit_all = exittapcount_2025 - exittapcount_2019)]

# Cut Down Data
cols_delta <- grep("delta", colnames(dt_trans_agg), value = TRUE)
cols_extract <- c("lsoa_code", cols_delta)

dt_trans_agg_cut <- dt_trans_agg[, ..cols_extract]

# Aggregate mean to each LSOA code
dt_trans_agg_cut <- dt_trans_agg_cut[, lapply(.SD, mean, na.rm = TRUE),
                                     by = "lsoa_code", .SDcols = cols_delta]

# Round mean
dt_trans_agg_cut <- dt_trans_agg_cut[, lapply(.SD, round, 2),
                                     by = "lsoa_code", .SDcols = cols_delta] 

# Rename columns
cols_delta_mean <- paste0("mean_", cols_delta)
setnames(dt_trans_agg_cut, cols_delta, cols_delta_mean)
dt_trans_agg_cut <- dt_trans_agg_cut[order(lsoa_code)]

# Cut some missing data
### 384-375 = 9 LSOAs cut
dt_trans_agg_cut <- dt_trans_agg_cut[!(mean_delta_entry_all == "NaN")]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Flag Deteriorated LSOAs
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Define LSOAs that are deprived
### Look at 5y decile movement - larger movements in deprivation
### Difference in flags for transportation - due to just London focus
lsoa_defs <- dt_imd[delta_decile_5y %in% c(-5, -4, -3, -2, -1), lsoa_code]
lsoa_defs_trans <- dt_imd[delta_decile_5y %in% c(-5, -4, -3), lsoa_code]

# Digital
dt_d <- dt_digi_agg_cut[, worsening_dep := ifelse(lsoa_code %in% lsoa_defs,
                                                             1, 0)]

# Energy
dt_e <- dt_energy_agg_cut[, worsening_dep := ifelse(lsoa_code %in% lsoa_defs,
                                                             1, 0)]

# Transport
dt_t <- dt_trans_agg_cut[, worsening_dep := ifelse(lsoa_code %in% lsoa_defs_trans,
                                                             1, 0)]

# Look at target distribution
table(dt_d$worsening_dep)
table(dt_e$worsening_dep)
table(dt_t$worsening_dep)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Export Data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
write.csv(dt_d, paste0(inp_clean,"01_digi_agg.csv"))
write.csv(dt_e, paste0(inp_clean,"02_energy_agg.csv"))
write.csv(dt_t, paste0(inp_clean,"03_trans_agg.csv"))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clean
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())
gc()

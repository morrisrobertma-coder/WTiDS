#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 01_digital.R
# Purpose of Script: Import and process digital connectivity data for project
#                    'Real-Time Monitoring of Local Authority Socioeconomic 
#                     Position and Deprivation Risk in the UK'
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
inp_digi <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/01_digi/")

# digital file names
file_digi_2025 <- c("202507_mobile_coverage_laua_r01.csv")
file_digi_2019 <- c("201909_mobile_laua_r01.csv")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mobile Coverage Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### 2025
dt_mc_25 <- as.data.table(read.csv(file = paste0(inp_digi, file_digi_2025)))
colnames(dt_mc_25) <- tolower(colnames(dt_mc_25))

### 2019
dt_mc_19 <- as.data.table(read.csv(file = paste0(inp_digi, file_digi_2019)))
colnames(dt_mc_19) <- tolower(colnames(dt_mc_19))





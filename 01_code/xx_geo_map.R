#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# xx_geo_map.R
# Purpose of Script: Process geographic mapping data for project
#                    'Real-Time Monitoring of Local Authority Socioeconomic
#                    Position and Deprivation Risk in the UK'
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())

#~~~~~~~~~~~~~~~~~~~~~~~~~
# Initialization
#~~~~~~~~~~~~~~~~~~~~~~~~~
# packages
library(data.table)

# paths
inp_path <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_geo/")

# imd file names (same as when downloaded from gov.uk)
file_geo <- c("ONSPD_MAY_2025_UK.csv")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Geographic Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dt <- as.data.table(read.csv(paste0(inp_path, file_geo)))

# Cut down
dt <- dt[,.(pcd, lsoa01, lsoa11, lsoa21,
            msoa01, msoa11, msoa21,
            lad = oslaua)]

dt <- unique(dt)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Geographic Data: Export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
write.csv(dt, file = paste0(inp_path,"geo_map_clean.csv"), row.names = FALSE)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clean 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())
gc()

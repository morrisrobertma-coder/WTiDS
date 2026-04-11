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
inp_path_geo <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_geo/")
inp_digi <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/01_digi/")
out_path <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_clean/")

# geographic mapping
file_geo <- c("geo_map_clean.csv")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Geographic Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dt_geo <- as.data.table(read.csv(paste0(inp_path_geo, file_geo)))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Fixed Broadband Data: Import & Clean
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Output
dt_digi_all <- data.table()

# Loop over dates
years <- c("2025","2019")

for (y in years){
  
  # List all postcode files
  files_digi <- list.files(paste0(inp_digi,"/",y,"/"))
  
  ## Import Files
  for (f in files_digi){
  
  ### Import
  dt_temp <- as.data.table(fread(paste0(inp_digi,"/",y,"/",f), check.names=FALSE))
  
  colnames(dt_temp) <- tolower(colnames(dt_temp))
  
  ### Cut down data: Focus on availability and 'unable to receive' factors
  cols_focus <- c("postcode","postcode_space","sfbb availability (% premises)",
                  "ufbb availability (% premises)","gigabit availability (% premises)",
                  "% of premises below the uso","% of premises unable to receive 10mbit/s",
                  "% of premises unable to receive 30mbit/s")
  
  if(y == 2019){
    cols_focus <- c("postcode","postcode_space","sfbb availability (% premises)",
                    "ufbb availability (% premises)",
                    "% of premises below the uso","% of premises unable to receive 10mbit/s",
                    "% of premises unable to receive 30mbit/s")
    
  }
  
  ### Cut down
  dt_temp <- dt_temp[, ..cols_focus]
  
  ### Rename columns
  if(y == 2025){
    colnames(dt_temp) <- c("postcode","postcode_space","sfbb_availaibility",
                         "ufbb_availaibility","gigabit_availability",
                         "below_uso","unable_10mbps","unable_30mbps")
  } else if (y == 2019){
    colnames(dt_temp) <- c("postcode","postcode_space","sfbb_availaibility",
                           "ufbb_availaibility",
                           "below_uso","unable_10mbps","unable_30mbps")
    
  }
  
  ### Add year
  setnames(dt_temp,
           old = names(dt_temp)[3:length(names(dt_temp))],
           new = paste0(names(dt_temp)[3:length(names(dt_temp))], "_", y))
  
  ### Bind
  dt_digi_all <- rbind(dt_digi_all,
                       dt_temp)
  
  ### Output 
  assign(paste0("dt_digi_all_", y), dt_digi_all)
  
  }
  dt_digi_all <- data.table()
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Fixed Broadband Data: Join 2025 & 2019
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dt_digi_all <- merge(dt_digi_all_2025,
                     dt_digi_all_2019,
                     by = c("postcode","postcode_space"),
                     all = T)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Fixed Broadband Data: Merge LSOA
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Merge LSOA to digital data
dt_digi_all <- merge(dt_digi_all,
                     dt_geo[,.(pcd, lsoa21)],
                     by.x = "postcode_space",
                     by.y = "pcd",
                     all.x = T)

### Filter data: a large portion of data is lost due to a lack of mapping of 
### postcode to LSOA. Differences occur between postcodes used for deliveries
### i.e. Royal Mail and those used by ONS for statistical analyses
dt_digi_all <- dt_digi_all[!is.na(lsoa21)]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Fixed Broadband Data: Export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Format Data
setcolorder(dt_digi_all, "lsoa21")
setnames(dt_digi_all, "lsoa21","lsoa_code")

### Export
write.csv(dt_digi_all, paste0(out_path,"01_digi_clean.csv"))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clean
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())
gc()


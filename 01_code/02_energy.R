#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 01_energy.R
# Purpose of Script: Import and process energy data for project
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
inp_en <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/02_energy/")

# digital file names
file_energy <- c("LSOA_domestic_elec_2010-2024.xlsx")

# geographic mapping
file_geo <- c("geo_map_clean.csv")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Geographic Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dt_geo <- as.data.table(read.csv(paste0(inp_path_geo, file_geo)))

# cut down
dt_geo_cut <- dt_geo[,.(lsoa01, lsoa11, lsoa21)]
dt_geo_cut <- unique(dt_geo_cut)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Electricity Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sheets <- c("2010","2015","2019","2024")

for (s in sheets){
   
    # import
    dt_en <- as.data.table(read_excel(paste0(inp_en, file_energy),
                                  sheet = paste0(s), skip = 4))
    
    # shift for 2024
    ## use 2024 as proxy for 2025
    if (s == "2024"){
      s_upd = "2025"
    } else {
      s_upd = s
    }
    
    # colnames
    colnames(dt_en) <- tolower(colnames(dt_en))
    setnames(dt_en, gsub("[\r\n ]+", "_", names(dt_en)))
    setnames(dt_en, gsub("[(]", "", names(dt_en)))
    setnames(dt_en, gsub("[)]", "", names(dt_en)))
    setnames(dt_en, gsub("_$", "", names(dt_en)))

    # filter
    dt_en <- dt_en[,.(lsoa_code, number_of_meters,
                      total_consumption_kwh, mean_consumption_kwh_per_meter,
                      median_consumption_kwh_per_meter)]
    
    # organise name
    setnames(dt_en,
             old = names(dt_en)[-1],
             new = paste0(names(dt_en)[-1], "_", s_upd))

    # output
    assign(paste0("dt_en_", s_upd), dt_en)
    
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Electricity Data: Merge
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Standardize to lsoa code 2011
### 2010 - join via lsoacode01
dt_en_2010 <- merge(dt_en_2010,
                    unique(dt_geo_cut[,.(lsoa01, lsoa11)]),
                    by.x = "lsoa_code",
                    by.y = "lsoa01",
                    all.x = T)







# Merge all data based on lsoa code
### 2025 - 2019
dt <- merge(dt_en_2025,
            dt_en_2019,
            by = "lsoa_code",
            all = T)

### 2015
dt <- merge(dt,
            dt_en_2015,
            by = "lsoa_code",
            all = T)

### 2010
#### join geo data - map msao from 01 to 11
dt_en_2010 <- merge(dt_en_2010,
                    dt_geo_cut,
                    by.x = "lsoa_code",
                    by.y = "lsoa01",
                    all.x = T)

#### aggregate data over new msoa code
dt_en_2010 <- dt_en_2010[, lsoa_code := ifelse(is.na(lsoa11), lsoa_code, lsoa11)]
dt_en_2010 <- dt_en_2010[, c("lsoa11","lsoa21") := NULL]
dt_en_2010 <- unique(dt_en_2010)

dt <- merge(dt,
            dt_en_2010,
            by = "lsoa_code",
            all = T)



# Clean
dts <- ls(pattern = "^dt_en")
rm(list = c(dts))



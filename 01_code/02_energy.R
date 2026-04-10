#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 02_energy.R
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
out_path <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_clean/")

# digital file names
file_energy <- c("LSOA_domestic_elec_2010-2024.xlsx")

# geographic mapping
file_geo <- c("geo_map_clean.csv")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Geographic Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dt_geo <- as.data.table(read.csv(paste0(inp_path_geo, file_geo)))

# ensure unique
dt_geo_cut <- dt_geo[, pcd := NULL]
dt_geo_cut <- unique(dt_geo)

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
    dt_en <- dt_en[,.(local_authority_code, local_authority,
                      msoa_code, middle_layer_super_output_area,
                      lsoa_code, number_of_meters,
                      total_consumption_kwh, mean_consumption_kwh_per_meter,
                      median_consumption_kwh_per_meter)]
    
    # organise name
    setnames(dt_en,
             old = names(dt_en)[6:length(names(dt_en))],
             new = paste0(names(dt_en)[6:length(names(dt_en))], "_", s_upd))

    # output
    assign(paste0("dt_en_", s_upd), dt_en)
    
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Electricity Data: Merge
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Standardize to lsoa 21 - currently using 2011 version
### 2010 - join via lsoacode01
dt_en_2010 <- merge(dt_en_2010,
                    unique(dt_geo_cut[,.(lsoa11, lsoa21, msoa11, msoa21)]),
                    by.x = c("lsoa_code","msoa_code"),
                    by.y = c("lsoa11","msoa11"),
                    all.x = T)

dt_en_2010 <- dt_en_2010[,':=' (lsoa_code = ifelse(is.na(lsoa21), lsoa_code,
                                                     lsoa21),
                                msoa_code = ifelse(is.na(msoa21), msoa_code,
                                                     msoa21))][
                                                       ,':='(lsoa21 = NULL,
                                                          msoa21 = NULL)]


# Merge all data based on lsoa code
### 2025 - 2019
dt <- merge(dt_en_2025[,.(lsoa_code, msoa_code, number_of_meters_2025,
                          total_consumption_kwh_2025, mean_consumption_kwh_per_meter_2025,
                          median_consumption_kwh_per_meter_2025)],
            dt_en_2019[,.(lsoa_code, msoa_code, number_of_meters_2019,
                          total_consumption_kwh_2019, mean_consumption_kwh_per_meter_2019,
                          median_consumption_kwh_per_meter_2019)],
            by = c("lsoa_code","msoa_code"),
            all = T)

#### Add 2015
dt <- merge(dt,
            dt_en_2015[,.(lsoa_code, msoa_code, number_of_meters_2015,
                          total_consumption_kwh_2015, mean_consumption_kwh_per_meter_2015,
                          median_consumption_kwh_per_meter_2015)],
            by = c("lsoa_code","msoa_code"),
            all = T)

#### Add 2010 - multiple joins happen
dt <- merge(dt,
            dt_en_2010[,.(lsoa_code, msoa_code, number_of_meters_2010,
                          total_consumption_kwh_2010, mean_consumption_kwh_per_meter_2010,
                          median_consumption_kwh_per_meter_2010)],
            by = c("lsoa_code","msoa_code"),
            all.x = T)


# check missings - less than 1% missing - discard
### 2015 - 63 discarded
dt <- dt[!is.na(number_of_meters_2015)] 

### 2019 - 1 discarded
dt <- dt[!is.na(number_of_meters_2019)]

### 2025 - 2 discarded
dt <- dt[!is.na(number_of_meters_2025)]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Electricity Data: Export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
write.csv(dt, paste0(out_path,"02_energy_clean.csv"))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clean
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dts <- ls(pattern = "^dt_en")
rm(list = c(dts))



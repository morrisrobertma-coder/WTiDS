#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 03_transport.R
# Purpose of Script: Import and process transport TFL data for project
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
library(sf)

# paths
inp_path_geo <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_geo/")
inp_trans <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/03_transport/")
out_path <- c("~/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/xx_clean/")

# geographic mapping
file_geo <- c("geo_map_clean.csv")

# lsoa co-ordinates mapping
file_lsoa <- c("LSOA_2021_EW_BSC_V4.shp")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Geographic Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Source: ONS
dt_geo <- as.data.table(read.csv(paste0(inp_path_geo, file_geo)))

# ensure unique
dt_geo_cut <- dt_geo[, pcd := NULL]
dt_geo_cut <- unique(dt_geo)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LSOA Location Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Source: ONS
dt_lsoa <- st_read(paste0(inp_path_geo,file_lsoa))
colnames(dt_lsoa) <- tolower(colnames(dt_lsoa))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Station Location Data: Import
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Source: https://github.com/urban-data-science-nexus/Spatial-Data-Analysis/blob/master/Stations_2022.csv
dt_station <- as.data.table(read.csv(paste0(inp_trans,"Stations_2022.csv")))

### Clean & Cut
colnames(dt_station) <- tolower(colnames(dt_station))
dt_station <- dt_station[,.(name, x, y)]
setnames(dt_station, c("name","x","y"),c("name","longitude","latitude"))
setcolorder(dt_station, "name")
dt_station <- dt_station[order(name)]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Station Footfall Data: Import & Clean
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Source: TFL
years <- c("2019","2020","2021","2022","2023","2024_2025")

for (i in years){
  
  # Import data
  dt_temp <- as.data.table(read.csv(paste0(inp_trans,"StationFootfall_",i,".csv")))
  
  # Clean  
  colnames(dt_temp) <- tolower(colnames(dt_temp))
  dt_temp <- dt_temp[, dayofweek := NULL]
  setcolorder(dt_temp, "station")
  
  if (i == "2024_2025"){
    
    # Add year
    dt_temp <- dt_temp[, year := substr(traveldate,1,4)]
    
    # Remove year from travel date
    dt_temp <- dt_temp[, traveldate := substr(traveldate, 5, 8)]
    
    dt_trans_2024 <- dt_temp[year == "2024"][, year := NULL]
    dt_trans_2025 <- dt_temp[year == "2025"][, year := NULL]
    
    setnames(dt_trans_2024,
             old = names(dt_trans_2024)[3:length(names(dt_trans_2024))],
             new = paste0(names(dt_trans_2024)[3:length(names(dt_trans_2024))], "_2024"))
    
    setnames(dt_trans_2025,
             old = names(dt_trans_2025)[3:length(names(dt_trans_2025))],
             new = paste0(names(dt_trans_2025)[3:length(names(dt_trans_2025))], "_2025"))
    
  } else {

  # Remove year from travel date
  dt_temp <- dt_temp[, traveldate := substr(traveldate, 5, 8)]
  
  setnames(dt_temp,
           old = names(dt_temp)[3:length(names(dt_temp))],
           new = paste0(names(dt_temp)[3:length(names(dt_temp))], "_", i))
  
  # Output 
  assign(paste0("dt_trans_", i), dt_temp)
  
  }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Station Footfall Data: Merge
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Initial Merge
dt_trans <- merge(dt_trans_2025,
                  dt_trans_2024,
                  on = c("station","traveldate"),
                  all = T)

# Loop Remaining
merge_dts <- c("dt_trans_2023","dt_trans_2022","dt_trans_2021",
               "dt_trans_2020","dt_trans_2019")

# Perform Minor Name Fix
for (f in merge_dts[-1]){
  
  fix <- get(f)
  fix <- fix[, station := ifelse(station == "Cannon Street ",
                                 "Cannon Street", station)]
  
  assign(paste0(f), fix)
  
}

for (m in merge_dts){
dt_trans <- merge(dt_trans,
                  get(m),
                  on = c("station","traveldate"),
                  all = T)

}

# Imputation Rule: 
### Some data values are NA. Impute with data for the previous day per location
cols_impute <- names(dt_trans)[-(1:2)]

dt_trans <- dt_trans[, (cols_impute) := lapply(.SD, nafill, type = "locf"),
                     by = "station", .SDcols = c(cols_impute)]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Merge Station Footfall & Latitude/Longitude
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Alter Tube Station Location name before join
# Base Data Fixes
dt_trans <- dt_trans[, station := ifelse(station == "Abbey Road DLR",
                                         "Abbey Road", station)]
dt_trans <- dt_trans[, station := ifelse(station == "Bethnal Green NR",
                                         "Bethnal Green LO", station)]
dt_trans <- dt_trans[, station := ifelse(station == "Burnham Bucks",
                                         "Burnham", station)]
dt_trans <- dt_trans[, station := ifelse(station == "Pontoon Dock DLR",
                                         "Pontoon Dock", station)]
dt_trans <- dt_trans[, station := ifelse(station == "Watford Met",
                                         "Watford", station)]
dt_trans <- dt_trans[, station := ifelse(station == "Sydenham SR",
                                         "Sydenham", station)]

# Station Mapping Fixes
dt_station <- dt_station[, name := gsub(" LU","", name)]
dt_station <- dt_station[, name := gsub("(Bak)","B", name)]
dt_station <- dt_station[, name := gsub(" SR","", name)]
dt_station <- dt_station[, name := gsub(" (Tramlink)","", name)]
dt_station <- dt_station[, name := gsub(" and Monument","",name)]
dt_station <- rbind(dt_station,
                    copy(dt_station[name == "Canary Wharf"][
                      , name := "Canary Wharf Elizabeth Line"]))

dt_station <- rbind(dt_station,
                    copy(dt_station[name == "Custom House"][
                      , name := "Custom House DLR"]),
                    copy(dt_station[name == "Custom House"][
                      , name := "Custom House EL"]),
                    copy(dt_station[name == "Custom House"][
                      , name := "Custom House Elizabeth Line"]))

dt_station <- dt_station[, name := ifelse(name == "Earl's Court",
                                          "Earls Court", name)]

dt_station <- dt_station[, name := ifelse(name == "Edgware Road (DIS)",
                                          "Edgware Road C&H", name)]

dt_station <- dt_station[, name := ifelse(name == "Edgware Road (B)",
                                          "Edgware Road B", name)]

dt_station <- dt_station[, name := ifelse(name == "Hammersmith (DIS)",
                                          "Hammersmith D&P", name)]

dt_station <- dt_station[, name := ifelse(name == "Hammersmith (H&C)",
                                          "Hammersmith C&H", name)]

dt_station <- dt_station[, name := ifelse(name == "Hayes and Harlington",
                                          "Hayes & Harlington", name)]

dt_station <- dt_station[, name := ifelse(name == "Heathrow Terminal 4 EL",
                                          "Heathrow T4 TfL Rail/HEx", name)]

dt_station <- dt_station[, name := ifelse(name == "Heathrow Terminal 5 EL",
                                          "Heathrow T5 TfL Rail/HEx", name)]

dt_station <- dt_station[, name := ifelse(name == "Heathrow Terminal 2 & 3 EL",
                                          "Heathrow T2&3 TfL Rail/HEx", name)]

dt_station <- rbind(dt_station,
                    copy(dt_station[name == "Heathrow Terminals 2 & 3 EL"][
                      , name := "Heathrow Terminals 2&3"]),
                    copy(dt_station[name == "Heathrow Terminals 2 & 3 EL"][
                      , name := "Heathrow T2&3 TfL Rail/HEx"]))

dt_station <- dt_station[, name := ifelse(name == "Kensington (Olympia)",
                                          "Kensington Olympia", name)]

dt_station <- dt_station[, name := ifelse(name == "King's Cross St. Pancras",
                                          "Kings Cross St Pancras", name)]

dt_station <- dt_station[, name := ifelse(name == "Langley",
                                          "Langley Berks", name)]

dt_station <- dt_station[, name := ifelse(name == "Liverpool Street NR",
                                          "Liverpool St NR", name)]

dt_station <- dt_station[, name := ifelse(name == "Paddington TfL",
                                          "Paddington", name)]

dt_station <- dt_station[, name := ifelse(name == "Paddington NR",
                                          "Paddington EL", name)]

dt_station <- dt_station[, name := ifelse(name == "Queen's Park",
                                          "Queens Park", name)]

dt_station <- dt_station[, name := gsub("Road Peckham","Rd Peckham", name)]

dt_station <- dt_station[, name := ifelse(name == "Regent's Park",
                                          "Regents Park", name)]

dt_station <- dt_station[, name := gsub("St. J", "St J", name)]
dt_station <- dt_station[, name := gsub("St. P", "St P", name)]

dt_station <- dt_station[, name := gsub("St John's", "St Johns", name)]
dt_station <- dt_station[, name := gsub("St Paul's", "St Pauls", name)]

dt_station <- dt_station[, name := ifelse(name == "Star Lane",
                                          "Star Lane DLR", name)]

dt_station <- dt_station[, name := ifelse(name == "Shepherd's Bush",
                                          "Shepherds Bush", name)]

dt_station <- rbind(dt_station,
                    copy(dt_station[name == "Shepherd's Bush Market"][
                      , name := "Shepherds Bush Market"]),
                    copy(dt_station[name == "Shepherd's Bush NR"][
                      , name := "Shepherds Bush LO"]))

dt_station <- dt_station[, name := ifelse(name == "Stratford International DLR",
                                          "Stratford International", name)]

dt_station <- dt_station[, name := ifelse(name == "Walthamstow Queen's Road",
                                          "Walthamstow Queens Road", name)]

dt_station <- rbind(dt_station,
                    copy(dt_station[name == "Woolwich Arsenal"][
                      , name := "Woolwich Arsenal DLR"]),
                    copy(dt_station[name == "Woolwich Arsenal"][
                      , name := "Woolwich Arsenal NR"]),
                    copy(dt_station[name == "Woolwich"][
                      , name := "Woolwich EL"]),
                    copy(dt_station[name == "Woolwich"][
                      , name := "Woolwich Elizabeth Line"]))

dt_station <- rbind(dt_station,
                    copy(dt_station[name == "West Croydon (Tramlink)"][
                      , name := "West Croydon"]))

# Check station name overlap
name_overlap <- merge(data.table(names_station = dt_station[, name],
                                 source_station = 1),
                      data.table(names_data = unique(dt_trans[, station]),
                           source_data = 1),
                      by.x = "names_station",
                      by.y = "names_data",
                      all = T)

# Left join - keep all transport data
dt <- merge(dt_trans,
            dt_station,
            by.x = "station",
            by.y = "name",
            all.x = T)

# Remove erroneous data - 4 stations have no location data
dt <- dt[!is.na(longitude)]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Join LSOA Geometric Data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Add spacial data column
dt_sf <- st_as_sf(dt,
                  coords = c("longitude","latitude"),
                  crs = 4326)

# Transform coordinate type
dt_sf <- st_transform(dt_sf, st_crs(dt_lsoa))

# Join data via geometry
dt_loc <- st_join(dt_sf, dt_lsoa)

# Data table conversion
dt_loc <- as.data.table(dt_loc)

# Cut down
cols_to_cut <- c("lsoa21nm","lsoa21nmw","bng_e","bng_n","lat","long","globalid","geometry")

dt <- dt_loc[, (cols_to_cut) := NULL]
setnames(dt, "lsoa21cd","lsoa_code")
setcolorder(dt, "lsoa_code")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Transport Data: Derived Columns
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Delta in Exit and Entry Data




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Transport Data: Export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clean
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = c(dts))

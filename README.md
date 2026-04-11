# Wider Topics in Data Science

Real Time Monitoring of Local Authority Socioeconomic Position and Deprivation Risk in the UK

```         
WTiDS Project\
├── 00_data/
│   ├── 00_imd/
│   │     ├── File_1_IoD2025_Index_of_Multiple_Deprivation.xlsx    <- 2025 IMD Data (gov.uk)
│   │     ├── File_1_-_IMD2019_Index_of_Multiple_Deprivation.xlsx  <- 2019 IMD Data (gov.uk)
│   │     ├── File_1_ID_2015_Index_of_Multiple_Deprivation.xlsx    <- 2015 IMD Data (gov.uk)
│   │     ├── 1871524.xls                                          <- 2010 IMD Data (gov.uk)
│   │     ├── IMD 2007 for DCLG 4 dec.xls                          <- 2007 IMD Data (gov.uk)   
│   │     └── ONSPD_MAY_2025_UK.csv                                <- Postcode Directory (Office for National Statistics)
│   │ 
│   ├── 01_digi/
│   │     ├── 2019  <- 121 files in format 2019_fixed_pc_coverage_POSTCODE.csv
│   │     └── 2025  <- 121 files in format 2019_fixed_pc_coverage_POSTCODE.csv
│   │ 
│   ├── 02_energy/
│   │     └── LSOA_domesitc_elec_2010-2024.xlsx  <- Domestic electricity usage data 2010 to 2024 per LSOA
│   │ 
│   ├── 03_transport/
│   │     ├── StationFootfall_2019.csv       <- TfL passenger numbers per London station 2019
│   │     ├── StationFootfall_2020.csv       <- TfL passenger numbers per London station 2020
│   │     ├── StationFootfall_2021.csv       <- TfL passenger numbers per London station 2021
│   │     ├── StationFootfall_2022.csv       <- TfL passenger numbers per London station 2022
│   │     ├── StationFootfall_2023.csv       <- TfL passenger numbers per London station 2023
│   │     └── StationFootfall_2024_2025.csv  <- TfL passenger numbers per London station 2024 & 2025
│   │ 
│   ├── xx_clean/
│   │     ├── 00_imd_data_clean.csv          <- Cleaned IMD Data
│   │     ├── 01_digi_clean.csv              <- Cleaned Digital Connectivity Data
│   │     ├── 02_energy_clean.csv            <- Cleaned Energy - Electricity Data
│   │     └── 03_transport.csv               <- Cleaned Transportation Data
│
└── 01_code\
    ├── 00_imd_data_processing.R    <- R file processing index of multiple deprivation data. 
    ├── 01_digital.R                <- R file processing digital connectivity data. 
    ├── 02_energy.R                 <- R file processing energy consumption data. 
    ├── 03_transport.R              <- R file processing tfl transportation data.
    ├── 04_visualisation.py         <- Python file visulising IMD data. 
    └── xx_geo_map.R                <- R file generating geographic boundary maps. 
```

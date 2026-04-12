#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 00_visualisation.py ----
# Purpose of Script: Visualise data for WTiDS Proposal
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Initialisation
#~~~~~~~~~~~~~~~~~~~~~~~~~~
# Libraries
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# print versions
print(f"Version Control Information:")
print(f"numpy version = {np.__version__}") # version: 2.3.4
print(f"pandas version = {pd.__version__}") # version: 2.3.3
print(f"seaborn version = {sns.__version__}") # version: 0.13.2

# Input/Output Paths
inp_path = "C:/Users/morri/OneDrive/00_Documents/06_university/00_university_of_sussex/05_summer_semester/03_wider_topics_in_data_science/00_repo/00_data/"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Import Data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# IMD
df = pd.read_csv(f"{inp_path}xx_clean/00_imd_data_clean.csv", index_col=0)

# Digital
df_digi = pd.read_csv(f"{inp_path}xx_clean/01_digi_clean.csv", index_col=0)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Visualisations - IMD
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Migration Matrices between Deciles 
years = ["07", "10", "15", "19", "25"]
transitions = list(zip(years[:-1], years[1:]))

# Migration Matrices Plot
fig, axes = plt.subplots(2, 2, figsize=(12,10))

fig.suptitle("IMD Decile Migrations Across Time per LSOA - [%]\n 1-Most Deprived, 10-Least Deprived ",
             fontsize=12, fontweight="bold")

axes = axes.flatten()

for i, (y1, y2) in enumerate(transitions):

    # Migration Matrix - Absolute
    mig = pd.crosstab(
        df[f"imd_decile_{y1}"],
        df[f"imd_decile_{y2}"]
    )

    # Migration Matrix - Relative
    mig = mig.reindex(index=range(1,11), columns=range(1,11))
    mig = mig.div(mig.sum(axis=1), axis=0).round(2)
     

    # Plot
    sns.heatmap(
        mig,
        ax=axes[i],
        cmap="Blues",
        annot=True,
        cbar=False,
        linewidths=0.3
    )
    
    year_map = {"07": "2007", "10": "2010", "15": "2015", "19": "2019", "25": "2025"}
    axes[i].set_title(f"{year_map[y1]} → {year_map[y2]}")
    
    axes[i].set_xlabel("To decile")
    axes[i].set_ylabel("From decile")

plt.tight_layout()
plt.show()

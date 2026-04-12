#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 05_eda.py ----
# Purpose of Script: Visualise data and perform EDA for WTiDS Proposal
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Initialisation
#~~~~~~~~~~~~~~~~~~~~~~~~~~
# Libraries
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from scipy.stats import ttest_ind

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
df_digi = pd.read_csv(f"{inp_path}xx_clean/01_digi_agg.csv", index_col=0)

# Energy
df_energy = pd.read_csv(f"{inp_path}xx_clean/02_energy_agg.csv", index_col=0)

# Transport
df_trans = pd.read_csv(f"{inp_path}xx_clean/03_trans_agg.csv", index_col=0)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# EDA - IMD
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

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Statistical Summaries
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Digital
digi_summary = df_digi.groupby('worsening_dep').agg({
    'mean_delta_sfbb_availaibility' : ['mean','std','count'],
    'mean_delta_ufbb_availaibility': ['mean','std','count'],
    'mean_delta_below_uso' : ['mean','std','count'],
    'mean_delta_unable_10mbps': ['mean','std','count'],
    'mean_delta_unable_30mbps': ['mean','std','count']})

digi_summary.columns = [
    f"{col[0]}_{col[1]}" for col in digi_summary.columns]

print(digi_summary)

# Energy
energy_summary = df_energy.groupby('worsening_dep').agg({
    'mean_delta_number_of_meters' : ['mean','std','count'],
    'mean_delta_total_consumption_kwh': ['mean','std','count'],
    'mean_delta_mean_consumption_kwh_per_meter' : ['mean','std','count'],
    'mean_delta_median_consumption_kwh_per_meter': ['mean','std','count']})

energy_summary.columns = [
    f"{col[0]}_{col[1]}" for col in energy_summary.columns]

print(energy_summary)

# Transport
trans_summary = df_trans.groupby('worsening_dep').agg({
    'mean_delta_entry_all': ['mean','std','count'],
    'mean_delta_exit_all': ['mean','std','count'],
    'mean_delta_entry_1y' : ['mean','std','count'],
    'mean_delta_entry_2y': ['mean','std','count'],
    'mean_delta_entry_3y': ['mean','std','count'],
    'mean_delta_entry_4y': ['mean','std','count'],
    'mean_delta_entry_5y': ['mean','std','count'],
    'mean_delta_entry_6y': ['mean','std','count'],
    'mean_delta_exit_1y': ['mean','std','count'],
    'mean_delta_exit_2y': ['mean','std','count'],
    'mean_delta_exit_3y': ['mean','std','count'],
    'mean_delta_exit_4y': ['mean','std','count'],
    'mean_delta_exit_5y': ['mean','std','count'],
    'mean_delta_exit_6y': ['mean','std','count']})

trans_summary.columns = [
    f"{col[0]}_{col[1]}" for col in trans_summary.columns]

print(trans_summary)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Statistical Testing
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Digital
### Define variables
vars_digi = ["mean_delta_sfbb_availaibility","mean_delta_ufbb_availaibility",
             "mean_delta_below_uso","mean_delta_unable_10mbps","mean_delta_unable_30mbps"]

### Loop through variables
res = []

for var in vars_digi:
    group_0 = df_digi[df_digi['worsening_dep'] == 0][var]
    group_1 = df_digi[df_digi['worsening_dep'] == 1][var]
    
    t_stat, p_value = ttest_ind(group_0, group_1, equal_var=False)

    res.append({
        'variable': var,
        'mean_not_worsened': group_0.mean(),
        'mean_worsened': group_1.mean(),
        'difference': group_1.mean() - group_0.mean(),
        't_stat': t_stat,
        'p_value': p_value,
        'n_not_worsened': len(group_0),
        'n_worsened': len(group_1)
        })

res_digi = pd.DataFrame(res)
res_digi['category'] = 'digital'

# Energy
### Define variables
vars_energy = ['mean_delta_number_of_meters', 'mean_delta_total_consumption_kwh',
               'mean_delta_mean_consumption_kwh_per_meter', 
               'mean_delta_median_consumption_kwh_per_meter']

### Loop through variables
res = []

for var in vars_energy:
    group_0 = df_energy[df_energy['worsening_dep'] == 0][var]
    group_1 = df_energy[df_energy['worsening_dep'] == 1][var]
    
    t_stat, p_value = ttest_ind(group_0, group_1, equal_var=False)

    res.append({
        'variable': var,
        'mean_not_worsened': group_0.mean(),
        'mean_worsened': group_1.mean(),
        'difference': group_1.mean() - group_0.mean(),
        't_stat': t_stat,
        'p_value': p_value,
        'n_not_worsened': len(group_0),
        'n_worsened': len(group_1)
        })

res_energy = pd.DataFrame(res)
res_energy['category'] = 'energy'

# Transport
### Define variables
vars_trans = ['mean_delta_entry_all', 'mean_delta_exit_all','mean_delta_entry_1y',
              'mean_delta_entry_2y','mean_delta_entry_3y', 'mean_delta_entry_4y',
              'mean_delta_entry_5y','mean_delta_entry_6y', 'mean_delta_exit_1y',
              'mean_delta_exit_2y', 'mean_delta_exit_3y', 'mean_delta_exit_4y',
              'mean_delta_exit_5y','mean_delta_exit_6y']

vars_trans = ['mean_delta_entry_5y', 'mean_delta_exit_5y']

### Loop through variables
res = []

for var in vars_trans:
    group_0 = df_trans[df_trans['worsening_dep'] == 0][var]
    group_1 = df_trans[df_trans['worsening_dep'] == 1][var]
    
    t_stat, p_value = ttest_ind(group_0, group_1, equal_var=False)

    res.append({
        'variable': var,
        'mean_not_worsened': group_0.mean(),
        'mean_worsened': group_1.mean(),
        'difference': group_1.mean() - group_0.mean(),
        't_stat': t_stat,
        'p_value': p_value,
        'n_not_worsened': len(group_0),
        'n_worsened': len(group_1)
        })

res_trans = pd.DataFrame(res)
res_trans['category'] = 'transport'

### Collect all results
res = pd.concat([res_digi, res_energy, res_trans])
res = res.round(2)

# Add significance levels
def significance(p):
    if p < 0.001:
        return '***'
    elif p < 0.01:
        return '**'
    elif p < 0.05:
        return '*'
    else:
        return ''

res['significance'] = res['p_value'].apply(significance)

# Alter variable names
res['variable'] = res['variable'].str.replace('mean_delta','Δ ').str.replace('_',' ')

# Sort results
res = res.sort_values('p_value')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Visualisation: Digital
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Superfast Broadband Availability
sns.kdeplot(
    data=df_digi,
    x='mean_delta_sfbb_availaibility',
    hue='worsening_dep',
    fill=True,
    common_norm=False,
    alpha=0.4
)





#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Visualisation: Energy
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Visualisation: Transportation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Violinplot
fig, axes = plt.subplots(1, 2, figsize=(12, 5))

# Assign Labels
labels = ['Not worsened', 'Worsened']

for ax in axes:
    ax.set_xticklabels(labels)
    ax.set_xlabel("")

# Exit Numbers
sns.violinplot(data = df_trans,
               x = "worsening_dep",
               y = "mean_delta_entry_5y",
               inner = "box",
               ax = axes[0])

axes[0].set_xlabel("LSOAs Deprivation Status",
           fontsize = 9)
axes[0].set_ylabel("Δ TfL Absolute Entry Numbers",
           fontsize = 9)
axes[0].set_title("5 Year Δ in Nominal TfL Entry Passenger Numers per Deprivation Risk",
          fontsize = 9)

# Entry Numbers
sns.violinplot(data = df_trans,
               x = "worsening_dep",
               y = "mean_delta_exit_5y",
               inner = "box",
               ax = axes[1])

axes[1].set_xlabel("LSOAs Deprivation Status",
           fontsize = 9)
axes[1].set_ylabel("Δ TfL Absolute Exit Numbers",
           fontsize = 9, labelpad=2)
axes[1].set_title("5 Year Δ in Nominal TfL Exit Passenger Numers per Deprivation Risk",
           fontsize = 9)

plt.show()


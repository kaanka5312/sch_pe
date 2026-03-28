# %% LIBRARIES
from pathlib import Path
import subprocess
import os
import sys
import pandas as pd
import numpy as np
from model_functions import fit_subject_parameters, generate_rl_signals, fit_subject_parameters_map
from data_utils import normalize_to_fmri, format_as_wide_csv
# Create a copy of the current environment and force UTF-8
env = os.environ.copy()
env["PYTHONIOENCODING"] = "utf-8"

def run_task(script_path):
    return subprocess.run([sys.executable, script_path], capture_output=True, text=True, env=env)
# %% =====================================================================
#  STAGE 1: DATA PREPERATION
# =====================================================================
# =====================================================================
# Setup paths
DATA_CSV = '/Users/kaankeskin/projects/sch_pe/data/raw/response.csv'
ASL_FILTERED = '/Users/kaankeskin/projects/sch_pe/data/processed/aslihan_filtered.csv'
FINAL_OUTPUT_CSV = '/Users/kaankeskin/projects/sch_pe/data/processed/RL_model_results.csv'
# Elif Ozge Subjects proper id numbers to use 
subjects = [
    8, 15, 16, 18, 20, 21, 24, 27, 28, 29, 30, 33, 35, 43, 45, 51,
    59, 60, 63, 64, 67, 68, 69, 74, 76, 77, 78, 80, 82, 85, 87, 88, 90,
    91, 92, 93, 94, 97, 99, 101, 102, 104, 105, 108, 109, 117, 119,
    120, 121, 124, 126, 132, 134, 135
]
# ELif ozge data
df_ozge = pd.read_csv(DATA_CSV)
# 2. Filter the dataframe to keep only the subjects in your list
df_ozge = df_ozge[df_ozge['denekId'].isin(subjects)]
# Aslihan subject reading and making money scale same for both
df_asl = pd.read_csv(ASL_FILTERED)
df_asl[['kazanc', 'toplam']] *= 2
all_merged = pd.concat([df_ozge,df_asl], axis=0, ignore_index=True)
pd.DataFrame(all_merged).to_csv('/Users/kaankeskin/projects/sch_pe/data/processed/all_subjects.csv', index=False)

# %% =====================================================================
#  STAGE 2: Computational Analysis
# This part runs respective scripts for the computational analysis
# =====================================================================
# Control analysis that does the model recover parameters succesfully
run_task('./recovery_MAP.py')
# Fits basic RL model 
run_task('./model_fitting_MAP.py')
# Checking subjects fit for visualization
run_task('./PPC_RL.py')
# Calculates win-stay-lose-shift 
run_task('./wsls.py')
# Comparison between adaptive alpha and fixed alpha
run_task('./model_cemre.py')
# Creating PE's for the fMRI analyiss 
run_task('./pe_regressor.py')

# %% =====================================================================
#  STAGE 3: Statistical Analysis for computational parameters 
# =====================================================================
# Comparison of model parameters (also somewhat in model_fitting_MAP)
# This extra includes potential covariates and lineer models.
run_task('./model_parameteres_statistic.py')
# Prediction Error comparison between groups and potential covariates 
# using lineer mixed model.
run_task('./PE_statistics.py')

if __name__ == "__main__":
    main()

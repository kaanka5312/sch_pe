# %% LIBRARIES
import pandas as pd
import numpy as np
from model_functions import fit_subject_parameters, generate_rl_signals, fit_subject_parameters_map
from data_utils import normalize_to_fmri, format_as_wide_csv
from group_comparison import run_group_stats


# %% This part is fitting new RL model to data 
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

# %% This part is to run the analysis
mix_subjects = np.unique(all_merged['denekId'])
def main():
    # 1. Load the behavioral data
    # This list will store a dictionary for every subject
    param_list = []
    pe_raw_list, pe_norm_list = [], []
    v_raw_list, v_norm_list = [], []
    for subj in mix_subjects:
        print(f"Fitting Subject: {subj}")
        subj_data = all_merged[all_merged['denekId'] == subj]
        # 2. Prepare choice and rewards
        # Ensure these column names match your CSV headers
        choices = subj_data['secim'].values 
        outcomes = subj_data['kazanc'].values
        # 3. MLE Parameter Fitting
        # This calls the function you defined in model_functions.py
        print(f"Subject {subj} - Unique outcomes: {np.unique(outcomes)}")
        alpha, tau = fit_subject_parameters_map(choices, outcomes)
        param_list.append({'denekId': subj, 'alpha': alpha, 'tau': tau})
        # 4. Generate trial-by-trial RL signals (PE and Value)
        # Using the updated function name from your model_functions.py
        pe_raw, v_raw = generate_rl_signals(alpha, choices, outcomes)
        # 5. Normalize & Save for fMRI
        # Maps signals to [-1, 1] as required for the GLM
        pe_norm = normalize_to_fmri(pe_raw)
        v_norm = normalize_to_fmri(v_raw)
        # 4. Collect for CSVs
        pe_raw_list.append({'denekId': subj, 'vector': pe_raw})
        pe_norm_list.append({'denekId': subj, 'vector': pe_norm})
        v_raw_list.append({'denekId': subj, 'vector': v_raw})
        v_norm_list.append({'denekId': subj, 'vector': v_norm})
    # Save 1: Parameters
    pd.DataFrame(param_list).to_csv('/Users/kaankeskin/projects/sch_pe/data/processed/model_parameters.csv', index=False)
    # Save 2-5: Vectors in Wide Format
    format_as_wide_csv(pe_raw_list, '/Users/kaankeskin/projects/sch_pe/data/processed/pe_raw.csv')
    format_as_wide_csv(pe_norm_list, '/Users/kaankeskin/projects/sch_pe/data/processed/pe_norm.csv')
    format_as_wide_csv(v_raw_list, '/Users/kaankeskin/projects/sch_pe/data/processed/v_raw.csv')
    format_as_wide_csv(v_norm_list, '/Users/kaankeskin/projects/sch_pe/data/processed/v_norm.csv')
    print("All CSVs generated successfully.")

# %% This part is for comparing the parameters between clinical groups statistics 
# 2. NOW CALL THE COMPARISON SCRIPT
run_group_stats(params_csv='/Users/kaankeskin/projects/sch_pe/data/processed/model_parameters.csv', 
                    subjects_csv='/Users/kaankeskin/projects/sch_pe/data/raw/subjects_list.csv')

if __name__ == "__main__":
    main()

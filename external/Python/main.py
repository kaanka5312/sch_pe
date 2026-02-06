# Main text of the Python version of the PE research
import pandas as pd
from model_functions import fit_subject, get_signals
from data_utils import normalize_to_fmri, save_to_task_folder

# Setup paths
DATA_CSV = 'data/raw/response.csv'
OUTPUT_DIR = '/Volumes/Elements/SoCAT/derivatives/rl_analysis/'

def main():
    df = pd.read_csv(DATA_CSV)
    subjects = df['denekId'].unique()
    
    for subj in subjects:
        print(f"Fitting Subject: {subj}")
        subj_data = df[df['denekId'] == subj]
        
        # Prepare choice (1/0) and rewards
        choices = subj_data['invest_choice'].values 
        outcomes = subj_data['points_received'].values
        
        # 1. MLE Parameter Fitting
        alpha, tau = fit_subject(choices, outcomes)
        
        # 2. Extract Signals
        pe_raw, v_raw = get_signals(alpha, choices, outcomes)
        
        # 3. Normalize & Save
        pe_norm = normalize_to_fmri(pe_raw)
        v_norm = normalize_to_fmri(v_raw)
        save_to_task_folder(subj, pe_norm, v_norm, OUTPUT_DIR)

if __name__ == "__main__":
    main()

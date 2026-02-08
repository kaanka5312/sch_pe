import pandas as pd
from scipy import stats
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

def run_group_stats(params_csv='/Users/kaankeskin/projects/sch_pe/data/processed/model_parameters.csv', 
                    pe_raw_csv='/Users/kaankeskin/projects/sch_pe/data/processed/pe_raw.csv', 
                    subjects_csv='/Users/kaankeskin/projects/sch_pe/data/raw/subjects_list.csv'):
    print("\n--- Starting Group Comparison (Alpha, Tau, and Raw PE) ---")
    
    # 1. Load Data
    params_df = pd.read_csv(params_csv)
    pe_df = pd.read_csv(pe_raw_csv)
    subjects_df = pd.read_csv(subjects_csv)

    # 2. Exclude subjects 9, 44, and 77 using the exact spacing from your file
    exclude_ids = [9, 44, 77]
    params_df = params_df[~params_df['denekId'].isin(exclude_ids)]
    pe_df = pe_df[~pe_df['denekId'].isin(exclude_ids)]
    subjects_df = subjects_df[~subjects_df[' task-id'].isin(exclude_ids)]

    # 3. Calculate Mean Raw PE for each subject
    # 'pe_raw.csv' columns are named 'trial_1', 'trial_2', etc.
    trial_cols = [c for c in pe_df.columns if c.startswith('trial_')]
    pe_df['mean_raw_pe'] = pe_df[trial_cols].mean(axis=1)

    # 4. Merge
    # First merge parameters and the calculated PE
    df = pd.merge(params_df, pe_df[['denekId', 'mean_raw_pe']], on='denekId')
    
    # Then merge with the original subject list using your specific spaced columns
    df = pd.merge(df, subjects_df[[' task-id', ' group']], 
                  left_on='denekId', right_on=' task-id')
    
    # Map the group name using the spaced column
    df['group_name'] = df[' group'].map({0: 'HC', 1: 'SZ'})

    # 5. Statistical Comparisons (t-tests)
    # We compare Alpha, Tau, and the Mean Raw PE
    metrics = ['alpha', 'tau', 'mean_raw_pe']
    
    for param in metrics:
        hc = df[df[' group'] == 0][param]
        sz = df[df[' group'] == 1][param]
        
        t_stat, p_val = stats.ttest_ind(hc, sz, nan_policy='omit')
        
        print(f"\n--- {param.upper()} ---")
        print(f"HC Mean: {hc.mean():.4f}, SZ Mean: {sz.mean():.4f}")
        print(f"t-stat: {t_stat:.4f}, p-value: {p_val:.4f}")

    # 6. Save 3-Panel Boxplot
    plt.figure(figsize=(15, 5))
    
    for i, param in enumerate(metrics):
        plt.subplot(1, 3, i+1)
        sns.boxplot(x='group_name', y=param, data=df, palette='Set2')
        # Add dots for individual subjects to show distribution
        sns.stripplot(x='group_name', y=param, data=df, color=".3", alpha=0.5)
        plt.title(f'Group Comparison: {param.capitalize()}')

    plt.tight_layout()
    plt.savefig('/Users/kaankeskin/projects/sch_pe/results/figures/group_results_full.png')
    print("\nResults saved to group_results_full.png")

if __name__ == "__main__":
    run_group_stats()

import pandas as pd
from scipy import stats
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

def run_group_stats(params_csv='/Users/kaankeskin/projects/sch_pe/data/processed/model_parameters.csv', 
                    pe_raw_csv='/Users/kaankeskin/projects/sch_pe/data/processed/pe_raw.csv', 
                    subjects_csv='/Users/kaankeskin/projects/sch_pe/data/raw/subjects_list.csv'):
    print("\n--- Starting Group Comparison (Phasewise Analysis) ---")
    
    # 1. Load Data
    params_df = pd.read_csv(params_csv)
    pe_df = pd.read_csv(pe_raw_csv)
    subjects_df = pd.read_csv(subjects_csv)

    # 2. Exclude subjects
    exclude_ids = [9, 44, 77]
    params_df = params_df[~params_df['denekId'].isin(exclude_ids)]
    pe_df = pe_df[~pe_df['denekId'].isin(exclude_ids)]
    subjects_df = subjects_df[~subjects_df[' task-id'].isin(exclude_ids)]

    # 3. Calculate Mean PE for each Phase (20 trial blocks)
    # Define trial column groups
    p1_cols = [f'trial_{i}' for i in range(1, 21)]
    p2_cols = [f'trial_{i}' for i in range(21, 41)]
    p3_cols = [f'trial_{i}' for i in range(41, 61)]
    all_cols = p1_cols + p2_cols + p3_cols

    # Compute Absolute Means (Amount of Surprise)
    pe_df['abs_pe_total'] = pe_df[all_cols].abs().mean(axis=1)
    pe_df['abs_pe_phase1'] = pe_df[p1_cols].abs().mean(axis=1)
    pe_df['abs_pe_phase2'] = pe_df[p2_cols].abs().mean(axis=1)
    pe_df['abs_pe_phase3'] = pe_df[p3_cols].abs().mean(axis=1)

    # 3. Merge
    df = pd.merge(params_df, pe_df[['denekId', 'abs_pe_total', 'abs_pe_phase1', 'abs_pe_phase2', 'abs_pe_phase3']], on='denekId')
    df = pd.merge(df, subjects_df[[' task-id', ' group']], left_on='denekId', right_on=' task-id')
    df['group_name'] = df[' group'].map({0: 'HC', 1: 'SZ'})

    # 4. Statistical Comparison of "Amount"
    metrics = ['abs_pe_total', 'abs_pe_phase1', 'abs_pe_phase2', 'abs_pe_phase3']
    
    print("\n--- Comparison of PE Amount (|PE|) ---")
    for m in metrics:
        hc = df[df[' group'] == 0][m]
        sz = df[df[' group'] == 1][m]
        t, p = stats.ttest_ind(hc, sz, nan_policy='omit')
        print(f"{m:15} | HC Mean: {hc.mean():.3f} | SZ Mean: {sz.mean():.3f} | p: {p:.4f}")

    # 5. Visualization
    plt.figure(figsize=(18, 5))
    for i, m in enumerate(metrics):
        plt.subplot(1, 4, i+1)
        sns.boxplot(x='group_name', y=m, data=df, palette='Set1')
        sns.stripplot(x='group_name', y=m, data=df, color=".3", alpha=0.4)
        plt.title(f'Amount: {m.replace("abs_pe_", "").capitalize()}')
    
    plt.tight_layout()
    plt.savefig('pe_amount_comparison.png')
    print("\nFigure saved as pe_amount_comparison.png")

if __name__ == "__main__":
    run_group_stats()

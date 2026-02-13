import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import permutation_test

# 1. VERİLERİ YÜKLE
PROJECT_FOLDER='C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/'
# Kendi bilgisayarındaki PROJECT_FOLDER yolunu kullandığından emin ol
all_subjects = pd.read_csv(PROJECT_FOLDER + 'data/processed/all_subjects.csv')
params_df = pd.read_csv(PROJECT_FOLDER + 'data/processed/final_group_parameters.csv')

# Sadece R2 >= 0 olan (modelle uyumlu) denekleri tutalım
all_subjects = all_subjects[all_subjects['denekId'].isin(params_df['denekId'].unique())]

# %% A. 3-FAZLI R2 ANALİZİ (20-20-20 Split)
def calculate_3phase_r2(all_subjects, params_df):
    results = []
    for _, row in params_df.iterrows():
        idx, alpha, tau = row['denekId'], row['alpha'], row['tau']
        subj_data = all_subjects[all_subjects['denekId'] == idx].reset_index(drop=True)
        choices, rewards = subj_data['yatirim'].values, subj_data['kazanc'].values
        
        v, v_safe, eps = 2.0, 2.0, 1e-10
        trial_nlls = []
        
        # Trial-by-trial NLL hesapla
        for t in range(len(choices)):
            prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
            p_actual = prob_invest if choices[t] == 1 else (1 - prob_invest)
            trial_nlls.append(-np.log(p_actual + eps))
            
            if choices[t] == 1:
                v = v + alpha * (rewards[t]/10.0 - v)
        
        # 3 Faza Böl (20-20-20)
        # Şans düzeyi NLL (her faz için): 20 * -ln(0.5)
        null_nll_phase = -np.log(0.5) * 20
        
        r2_p1 = 1 - (sum(trial_nlls[0:20]) / null_nll_phase)
        r2_p2 = 1 - (sum(trial_nlls[20:40]) / null_nll_phase)
        r2_p3 = 1 - (sum(trial_nlls[40:60]) / null_nll_phase)
        
        results.append({
            'denekId': idx, 
            'r2_phase1': r2_p1, 
            'r2_phase2': r2_p2, 
            'r2_phase3': r2_p3
        })
    return pd.DataFrame(results)

# %% B. WSLS ANALİZİ
def calculate_wsls(df):
    wsls_list = []
    for idx in df['denekId'].unique():
        subj_data = df[df['denekId'] == idx].reset_index(drop=True)
        choices, rewards = subj_data['yatirim'].values, subj_data['kazanc'].values
        ws_num, ws_den, ls_num, ls_den = 0, 0, 0, 0
        for t in range(1, len(choices)):
            if choices[t-1] == 1:
                if rewards[t-1] > 0: # Win
                    ws_den += 1
                    if choices[t] == 1: ws_num += 1
                else: # Loss
                    ls_den += 1
                    if choices[t] == 0: ls_num += 1
        wsls_list.append({
            'denekId': idx,
            'win_stay': ws_num / ws_den if ws_den > 0 else np.nan,
            'loss_shift': ls_num / ls_den if ls_den > 0 else np.nan
        })
    return pd.DataFrame(wsls_list)

# ANALİZLERİ BİRLEŞTİR
phase_res = calculate_3phase_r2(all_subjects, params_df)
wsls_res = calculate_wsls(all_subjects)
final_analysis_df = params_df.merge(phase_res, on='denekId').merge(wsls_res, on='denekId')

# %% C. İSTATİSTİK (PERMÜTASYON TESTİ)
metrics = ['win_stay', 'loss_shift', 'r2_phase1', 'r2_phase2', 'r2_phase3']
p_vals = {}
for m in metrics:
    g0 = final_analysis_df[final_analysis_df['group'] == 0][m].dropna().values
    g1 = final_analysis_df[final_analysis_df['group'] == 1][m].dropna().values
    res = permutation_test((g0, g1), lambda x, y: np.mean(x) - np.mean(y), 
                           permutation_type='independent', n_resamples=10000)
    p_vals[m] = res.pvalue

# %% D. GÖRSELLEŞTİRME
fig, axes = plt.subplots(2, 3, figsize=(18, 12))
titles = ['Win-Stay', 'Loss-Shift', 'R2 Faz 1 (1-20)', 'R2 Faz 2 (21-40)', 'R2 Faz 3 (41-60)']

for i, m in enumerate(metrics):
    ax = axes.flatten()[i]
    sns.boxplot(x='group', y=m, data=final_analysis_df, ax=ax, palette='Set2')
    sns.stripplot(x='group', y=m, data=final_analysis_df, ax=ax, color='black', alpha=0.3)
    ax.set_title(f"{titles[i]}\np = {p_vals[m]:.4f}")

axes.flatten()[-1].axis('off') # Boş kalan son kutuyu gizle
plt.tight_layout()
plt.show()

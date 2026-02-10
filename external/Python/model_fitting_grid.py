# %% LIBRARIES
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import mannwhitneyu
from model_functions import compute_log_likelihood, compute_null_log_likelihood_chance

# %% PATHS & DATA LOADING
#PROJECT_FOLDER = '~/OneDrive/Belgeler/GitHub/sch_pe/'
PROJECT_FOLDER = '/Users/kaankeskin/projects/sch_pe/'
all_subjects = pd.read_csv(PROJECT_FOLDER + 'data/processed/all_subjects.csv')
subj_list = pd.read_csv(PROJECT_FOLDER + 'data/raw/subjects_list.csv') # denekId ve group sütunları olmalı

# %% BRUTE-FORCE GRID SEARCH
# Hassasiyeti artırmak için 100x100'lük bir ızgara
alpha_grid = np.linspace(0.001, 1.0, 100)
tau_grid = np.linspace(0.01, 5.0, 100)

final_results = []

print("Brute-force optimizasyon başlıyor (Bu işlem biraz zaman alabilir)...")
for idx in all_subjects['denekId'].unique():
    subj_data = all_subjects[all_subjects['denekId'] == idx]
    choices = subj_data['yatirim'].to_numpy()
    outcomes = subj_data['kazanc'].to_numpy()
    
    null_nll = compute_null_log_likelihood_chance(choices)
    best_nll = np.inf
    best_params = (0, 0)
    
    # Grid Search Döngüsü
    for a in alpha_grid:
        for t in tau_grid:
            current_nll = compute_log_likelihood([a, t], choices, outcomes)
            if current_nll < best_nll:
                best_nll = current_nll
                best_params = (a, t)
    
    # R2 ve Sonuçlar
    pseudo_r2 = 1 - (best_nll / null_nll)
    final_results.append({
        'denekId': idx,
        'alpha': best_params[0],
        'tau': best_params[1],
        'pseudo_r2': pseudo_r2,
        'nll': best_nll
    })

# %% GROUP MERGING & STATS
# 1. Sütun isimlerindeki gizli boşlukları temizleyelim (strip)
subj_list.columns = subj_list.columns.str.strip()

# 2. Merged işlemini düzeltelim
# res_df içindeki 'denekId' ile subj_list içindeki 'subj' sütununu eşleştiriyoruz.
# (Eğer denek numaraların 'task-id' sütununda ise right_on='task-id' yapabilirsin)
merged_df = res_df.merge(subj_list[['subj', 'group']], 
                         left_on='denekId', 
                         right_on='subj', 
                         how='inner')

# 3. İstatistik döngüsünü de temizlenen isimlere göre güncelleyelim
stats_results = {}
for col in ['alpha', 'tau', 'pseudo_r2']:
    g_hc = merged_df[merged_df['group'] == 'HC'][col]
    g_sz = merged_df[merged_df['group'] == 'SZ'][col]
    
    # Boş küme kontrolü (Eşleşme hatası varsa önlemek için)
    if len(g_hc) > 0 and len(g_sz) > 0:
        stat, p = mannwhitneyu(g_hc, g_sz)
        stats_results[col] = p
    else:
        print(f"Uyarı: {col} için grup verisi eksik (HC: {len(g_hc)}, SZ: {len(g_sz)})")
        stats_results[col] = np.nan
# %% VISUALIZATION (BOXPLOTS)
fig, axes = plt.subplots(1, 3, figsize=(18, 6))
params_to_plot = ['alpha', 'tau', 'pseudo_r2']
titles = ['Öğrenme Hızı (Alpha)', 'Karar Hassasiyeti (Tau)', 'Model Uyumu (Pseudo R2)']

for i, param in enumerate(params_to_plot):
    sns.boxplot(x='group', y=param, data=merged_df, ax=axes[i], palette='Set2')
    sns.stripplot(x='group', y=param, data=merged_df, ax=axes[i], color='black', alpha=0.3)
    axes[i].set_title(f"{titles[i]}\n(p = {stats_results[param]:.4f})")
    axes[i].set_xlabel("Grup")
    axes[i].set_ylabel("Değer")

plt.tight_layout()
plt.savefig(PROJECT_FOLDER + 'reports/figures/group_comparison_bruteforce.png')
merged_df.to_csv(PROJECT_FOLDER + 'data/processed/final_group_parameters.csv', index=False)
plt.show()

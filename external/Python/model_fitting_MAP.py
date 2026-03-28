# %% LIBRARIES
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import mannwhitneyu
from model_functions import compute_log_likelihood, compute_null_log_likelihood_chance
from scipy.stats import permutation_test, levene
# %% PATHS & DATA LOADING
#PROJECT_FOLDER = 'C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/'
PROJECT_FOLDER = '/Users/kaankeskin/projects/sch_pe/'
all_subjects = pd.read_csv(PROJECT_FOLDER + 'data/processed/all_subjects.csv')
subj_list = pd.read_csv(PROJECT_FOLDER + 'data/raw/subjects_list.csv') # denekId ve group sütunları olmalı

# %% ROBUST MAP ESTIMATION (REPLACES GRID SEARCH)
# Import your new robust function at the top of your script if you haven't already:
from model_functions import fit_subject_parameters_map_robust
final_results = []
print("Robust MAP optimizasyonu başlıyor (Çoklu Başlangıç Noktaları ile)...")
for idx in all_subjects['denekId'].unique():
    subj_data = all_subjects[all_subjects['denekId'] == idx]
    choices = subj_data['yatirim'].to_numpy()
    outcomes = subj_data['kazanc'].to_numpy()
    # 1. Null Likelihood Hesapla (Pseudo R2 için)
    null_nll = compute_null_log_likelihood_chance(choices)
    # 2. Robust MAP Fitting (Grid Search yerine)
    try:
        # Fonksiyon sana best_alpha ve best_tau döndürecek
        best_params = fit_subject_parameters_map_robust(choices, outcomes)
        best_alpha = best_params[0]
        best_tau = best_params[1]
        # 3. Bulunan parametrelerle Log-Likelihood hesapla (SADECE Likelihood, Prior'suz)
        # Neden? Çünkü R2 hesaplamasında prior'ı değil, veriye olan saf uyumu kullanmalıyız.
        best_nll = compute_log_likelihood([best_alpha, best_tau], choices, outcomes)
    except Exception as e:
        print(f"Denek {idx} için optimizasyon çöktü: {e}")
        best_alpha, best_tau, best_nll = np.nan, np.nan, np.nan
    # 4. R2 ve Sonuçları Kaydet
    pseudo_r2 = 1 - (best_nll / null_nll)
    final_results.append({
        'denekId': idx,
        'alpha': best_alpha,
        'tau': best_tau,
        'pseudo_r2': pseudo_r2,
        'nll': best_nll
    })
# Listeyi DataFrame'e donustur 
res_df = pd.DataFrame(final_results)

# Bu aslinda cok mantikli degil o yuzden kaldirdim. Zaten modele gore hareket
# etmemis katilimcilarin da degerleri burada olmali ki model paremeterlerini
# gruplar arasinda karsilastirabilelim.
# Negatif Pseudo R2 değerine sahip (model dışı) denekleri ayıkla
# NaN değerleri (çöken fitler) de burada otomatik olarak temizlenmiş olur
# res_df = res_df[res_df['pseudo_r2'] >= 0].copy()
 
# %% GROUP MERGING & STATS
# 1. Sütun isimlerindeki gizli boşlukları temizleyelim (strip)
subj_list.columns = subj_list.columns.str.strip()
# 2. Merged işlemini düzeltelim
# res_df içindeki 'denekId' ile subj_list içindeki 'subj' sütununu eşleştiriyoruz.
# (Eğer denek numaraların 'task-id' sütununda ise right_on='task-id' yapabilirsin)
merged_df = res_df.merge(subj_list[['task-id', 'group']], 
                         left_on='denekId', 
                         right_on='task-id', 
                         how='inner')
exclude_ids = [9, 44, 77]
# Merge data (Inner join)
merged_df = merged_df[~merged_df['denekId'].isin(exclude_ids)].copy()

# 3. İstatistik döngüsünü de temizlenen isimlere göre güncelleyelim
# Mann withney u ile kiyaslama 
stats_results = {}
for col in ['alpha', 'tau', 'pseudo_r2']:
    g_hc = merged_df[merged_df['group'] == 0][col]
    g_sz = merged_df[merged_df['group'] == 1][col]
    # Boş küme kontrolü (Eşleşme hatası varsa önlemek için)
    if len(g_hc) > 0 and len(g_sz) > 0:
        stat, p = mannwhitneyu(g_hc, g_sz)
        stats_results[col] = p
    else:
        print(f"Uyarı: {col} için grup verisi eksik (HC: {len(g_hc)}, SZ: {len(g_sz)})")
        stats_results[col] = np.nan

# Varyansların (dağılım genişliğinin) eşitliğini Levene Testi ile kıyaslama
levene_results = {}
print("\n--- LEVENE TESTİ (VARYANS EŞİTLİĞİ) ---")
print(f"{'Parametre':<10} | {'HC Variance':<12} | {'SZ Variance':<12} | {'Levene p-val':<10}")
print("-" * 60)
for col in ['alpha', 'tau', 'pseudo_r2']:
    # Dropna() eklemek iyi bir alışkanlıktır, eksik veriler testi bozmasın
    g_hc = merged_df[merged_df['group'] == 0][col].dropna()
    g_sz = merged_df[merged_df['group'] == 1][col].dropna()
    # Boş küme kontrolü
    if len(g_hc) > 0 and len(g_sz) > 0:
        # Levene Testini çalıştır
        stat, p = levene(g_hc, g_sz)
        levene_results[col] = p
        # Gerçek varyans değerlerini hesapla (ddof=1 örneklem varyansı için)
        hc_var = np.var(g_hc, ddof=1)
        sz_var = np.var(g_sz, ddof=1)
        print(f"{col:<10} | {hc_var:<12.4f} | {sz_var:<12.4f} | {p:<10.4f}")
    else:
        print(f"Uyarı: {col} için grup verisi eksik (HC: {len(g_hc)}, SZ: {len(g_sz)})")
        levene_results[col] = np.nan

# %% Non-parametrik olarak kiyaslama
# 1. Test istatistiğini tanımlayalım (İki grup ortalaması arasındaki fark)
def statistic(x, y):
    return np.median(x) - np.median(y)
# 2. İstatistik döngüsünü Permütasyon Testi ile güncelleyelim
stats_results = {}
print(f"{'Parametre':<10} | {'HC Mean':<10} | {'SZ Mean':<10} | {'Fark (HC-SZ)':<12} | {'Perm. p-val':<10}")
print("-" * 65)
for col in ['alpha', 'tau', 'pseudo_r2']:
    g_hc = merged_df[merged_df['group'] == 0][col].values
    g_sz = merged_df[merged_df['group'] == 1][col].values
    # Boş küme kontrolü
    if len(g_hc) > 0 and len(g_sz) > 0:
        # Permütasyon Testi (10,000 iterasyon)
        # 'independent' iki bağımsız grubu (HC vs SZ) temsil eder
        res = permutation_test((g_hc, g_sz), statistic, 
                               permutation_type='independent', 
                               n_resamples=10000, 
                               alternative='two-sided')
        stats_results[col] = res.pvalue
        # Sonuçları ekrana yazdır
        diff = np.mean(g_hc) - np.mean(g_sz)
        print(f"{col:<10} | {np.mean(g_hc):<10.3f} | {np.mean(g_sz):<10.3f} | {diff:<12.3f} | {res.pvalue:<10.4f}")
    else:
        print(f"Uyarı: {col} için grup verisi eksik (HC: {len(g_hc)}, SZ: {len(g_sz)})")
        stats_results[col] = np.nan

# %% VISUALIZATION (BOXPLOTS)
# 1. Apply the global formatting (fonts, axes, sizes)
from config import GROUP_COLORS # Imports your dictionary!
plt.style.use('./paper_theme.mplstyle')
group_mapping = {0 : 'HC', 1 : 'SZ'}
merged_df['group'] = merged_df['group'].replace(group_mapping)
fig, axes = plt.subplots(1, 3, figsize=(12, 5))
params_to_plot = ['alpha', 'tau', 'pseudo_r2']
titles = ['Alpha', 'Tau', 'Pseudo R2']
for i, param in enumerate(params_to_plot):
    sns.boxplot(x='group', y=param, data=merged_df, ax=axes[i], palette=GROUP_COLORS)
    sns.stripplot(x='group', y=param, data=merged_df, ax=axes[i], color='black', alpha=0.3)
    axes[i].set_title(f"{titles[i]}\n(p = {stats_results[param]:.4f})")
    axes[i].set_xlabel("Group")
    axes[i].set_ylabel("Value")
plt.savefig(PROJECT_FOLDER + 'results/figures/group_comparison_bruteforce.png')
merged_df.to_csv(PROJECT_FOLDER + 'data/processed/final_group_parameters.csv', index=False)
plt.show()

# %% 1. LIBRARIES & DATA SETUP
import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.optimize import minimize
from scipy.stats import beta, gamma
from model_functions import fit_subject_parameters_map_robust, compute_log_likelihood
# %% 1. YOLLAR VE VERİ YÜKLEME
# Kendi bilgisayar yoluna göre düzenle
#PROJECT_FOLDER = 'C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/'
PROJECT_FOLDER = '/Users/kaankeskin/projects/sch_pe/'
all_subjects = pd.read_csv(os.path.expanduser(PROJECT_FOLDER + 'data/processed/all_subjects.csv'))
subj_list = pd.read_csv(os.path.expanduser(PROJECT_FOLDER + 'data/raw/subjects_list.csv'))
subj_list.columns = subj_list.columns.str.strip()

# %% 3. MODEL FONKSİYONLARI (20 ve 60 TL yapısına göre)
def compute_cemre_log_likelihood(params, choices, rewards):
    a0, epsilon, tau = params
    v, v_keep, alpha_t = 20.0/60.0, 20.0/60.0, a0
    nll, eps_val = 0, 1e-10
    r_norm = rewards / 60.0
    for t in range(len(choices)):
        # Karar Olasılığı (Softmax)
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_keep)))
        p_choice = prob_invest if choices[t] == 1 else (1 - prob_invest)
        nll -= np.log(p_choice + eps_val)
        if choices[t] == 1:
            # Alpha Güncelleme (Cemre et al., 2022)
            # Eğer Trustee Paylaştıysa alpha artar, El Koyduysa alpha azalır
            if r_norm[t] > v_keep:
                alpha_t = np.clip(alpha_t + epsilon, 0.001, 1.0)
            else:
                alpha_t = np.clip(alpha_t - epsilon, 0.001, 1.0)
            # Değer Güncelleme
            v = v + alpha_t * (r_norm[t] - v)
    return nll
def compute_cemre_neg_log_posterior(params, choices, rewards):
    a0, epsilon, tau = params
    neg_ll = compute_cemre_log_likelihood(params, choices, rewards)
    prior_a0 = beta.logpdf(a0, 1.1, 1.1)
    prior_tau = gamma.logpdf(tau, 2.5, scale=2.5) # Senin /60.0 formatına uygun prior
    # Epsilon için uniform prior varsayıyoruz (sadece sınırlar içinde optimize edilecek)
    return neg_ll - (prior_a0 + prior_tau)
def fit_cemre_map_robust(choices, rewards):
    best_res = None
    # Epsilon sınırları [0.0, 0.5] olarak ayarlandı
    bnds = [(1e-5, 0.99999), (0.0, 0.5), (0.01, 30.0)] 
    starting_points = [[0.1, 0.01, 1.5], [0.5, 0.05, 4.5], [0.9, 0.1, 10.0]]
    for start in starting_points:
        res = minimize(compute_cemre_neg_log_posterior, x0=start, args=(choices, rewards), bounds=bnds, method='L-BFGS-B')
        if best_res is None or res.fun < best_res.fun: best_res = res
    return best_res.x


# %% 3. ANA DÖNGÜ (BIC İLE MODEL KIYASLAMA)
results = []
print("Robust MAP Tabanlı Model Kıyaslaması Başlıyor...")
for idx in all_subjects['denekId'].unique():
    subj_data = all_subjects[all_subjects['denekId'] == idx]
    choices = subj_data['yatirim'].to_numpy()
    rewards = subj_data['kazanc'].to_numpy()
    n_trials = len(choices)
    try:
        # --- 1. SIMPLE MODEL (Kendi import ettiğin fonksiyonlar) ---
        # k = 2 (Alpha, Tau)
        params_simple = fit_subject_parameters_map_robust(choices, rewards)
        nll_simple = compute_log_likelihood(params_simple, choices, rewards)
        bic_simple = 2 * np.log(n_trials) + 2 * nll_simple
        # --- 2. CEMRE MODEL (Yukarıda tanımladığımız adaptif model) ---
        # k = 3 (A0, Epsilon, Tau)
        params_cemre = fit_cemre_map_robust(choices, rewards)
        nll_cemre = compute_cemre_log_likelihood(params_cemre, choices, rewards)
        bic_cemre = 3 * np.log(n_trials) + 2 * nll_cemre
        results.append({
            'denekId': idx,
            'bic_simple': bic_simple,
            'bic_cemre': bic_cemre,
            'delta_bic': bic_simple - bic_cemre, # Pozitif değer Cemre'nin daha iyi olduğunu gösterir
            'winner': 'Cemre' if bic_cemre < bic_simple else 'Simple'
        })
    except Exception as e:
        print(f"Denek {idx} için fitting hatası: {e}")
res_df = pd.DataFrame(results)
merged_df = res_df.merge(subj_list[['task-id', 'group']], left_on='denekId', right_on='task-id', how='inner')


# %% 4. İSTATİSTİK VE GÖRSELLEŞTİRME
print("\n--- GRUP BAZINDA MODEL TERCİHİ ---")
print(merged_df.groupby(['group', 'winner']).size().unstack(fill_value=0))
total_simple = merged_df['bic_simple'].sum()
total_cemre = merged_df['bic_cemre'].sum()
group_improvement = total_simple - total_cemre
print(f"\n--- BÜTÜNCÜL KANIT (Lower is better) ---")
print(f"Simple RL Toplam BIC: {total_simple:.2f}")
print(f"Cemre Model Toplam BIC: {total_cemre:.2f}")
print(f"Toplam İyileşme (Evidence Gain): {group_improvement:.2f}")

# PAIRED SLOPE GRAPH
plt.figure(figsize=(10, 6))
for i in range(len(merged_df)):
    y1 = merged_df.iloc[i]['bic_simple']
    y2 = merged_df.iloc[i]['bic_cemre']
    color = 'green' if y2 < y1 else 'red' # Yeşil = Cemre Modeli BIC'i düşürdü
    plt.plot([0, 1], [y1, y2], marker='o', color=color, alpha=0.4)
plt.xticks([0, 1], ['Simple RL', 'Cemre (Adaptive)'])
plt.ylabel('BIC Skoru (Düşük olan daha iyi)')
plt.title(f'Denek Bazlı Model Geçişleri\nToplam İyileşme: {group_improvement:.2f}')
plt.grid(axis='y', linestyle='--', alpha=0.3)
plt.show()
# CUMULATIVE DELTA GRAPH
merged_df = merged_df.sort_values('denekId').reset_index(drop=True)
plt.figure(figsize=(10, 5))
plt.step(range(len(merged_df)), merged_df['delta_bic'].cumsum(), where='mid', color='blue', linewidth=2)
plt.axhline(0, color='black', linestyle='--')
plt.fill_between(range(len(merged_df)), merged_df['delta_bic'].cumsum(), 0, alpha=0.2, color='blue')
plt.title('Kümülatif Model Kanıtı (Cum. Delta BIC)\nYukarı Doğru Gidiş Cemre Modelini Destekler')
plt.xlabel('Katılımcı Sayısı')
plt.ylabel('Kümülatif İyileşme (Delta BIC)')
plt.show()


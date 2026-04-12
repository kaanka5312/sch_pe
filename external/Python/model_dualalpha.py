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
# %% 2. DUAL ALPHA MODEL FONKSİYONLARI 
def compute_dual_alpha_log_likelihood(params, choices, rewards):
    alpha_pos, alpha_neg, tau = params
    v, v_keep = 20.0/60.0, 20.0/60.0
    nll, eps_val = 0, 1e-10
    r_norm = rewards / 60.0
    for t in range(len(choices)):
        # Karar Olasılığı (Softmax)
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_keep)))
        p_choice = prob_invest if choices[t] == 1 else (1 - prob_invest)
        nll -= np.log(p_choice + eps_val)
        if choices[t] == 1:
            # Prediction Error Hesaplama
            pe = r_norm[t] - v
            # Dual Alpha Güncellemesi (Pozitif ve Negatif PE için ayrı öğrenme)
            if pe > 0:
                v = v + alpha_pos * pe
            else:
                v = v + alpha_neg * pe
    return nll
def compute_dual_alpha_neg_log_posterior(params, choices, rewards):
    alpha_pos, alpha_neg, tau = params
    neg_ll = compute_dual_alpha_log_likelihood(params, choices, rewards)
    # Her iki alpha için de beta prior kullanıyoruz
    prior_ap = beta.logpdf(alpha_pos, 1.1, 1.1)
    prior_an = beta.logpdf(alpha_neg, 1.1, 1.1)
    prior_tau = gamma.logpdf(tau, 2.5, scale=2.5) 
    return neg_ll - (prior_ap + prior_an + prior_tau)
def fit_dual_alpha_map_robust(choices, rewards):
    best_res = None
    # Sınırlar: [alpha_pos, alpha_neg, tau]
    bnds = [(1e-5, 0.99999), (1e-5, 0.99999), (0.01, 30.0)] 
    # Farklı başlangıç noktaları ile lokal minimumdan kaçınma
    starting_points = [[0.1, 0.1, 1.5], [0.5, 0.5, 4.5], [0.9, 0.9, 10.0]]
    for start in starting_points:
        res = minimize(compute_dual_alpha_neg_log_posterior, x0=start, args=(choices, rewards), bounds=bnds, method='L-BFGS-B')
        if best_res is None or res.fun < best_res.fun: 
            best_res = res
    return best_res.x


# %% 3. ANA DÖNGÜ (BIC İLE MODEL KIYASLAMA VE NULL MODEL)
results = []
print("Robust MAP Tabanlı Model Kıyaslaması Başlıyor (Null Model Dahil)...")
for idx in all_subjects['denekId'].unique():
    subj_data = all_subjects[all_subjects['denekId'] == idx]
    choices = subj_data['yatirim'].to_numpy()
    rewards = subj_data['kazanc'].to_numpy()
    n_trials = len(choices)
    try:
        # --- 0. NULL MODEL (Rastgele Seçim / Pure Chance) ---
        # 0 parametre (k=0). Olasılık her zaman 0.5.
        nll_null = -n_trials * np.log(0.5)
        bic_null = 0 * np.log(n_trials) + 2 * nll_null
        # --- 1. SIMPLE MODEL ---
        # k = 2 (Alpha, Tau)
        params_simple = fit_subject_parameters_map_robust(choices, rewards)
        nll_simple = compute_log_likelihood(params_simple, choices, rewards)
        bic_simple = 2 * np.log(n_trials) + 2 * nll_simple
        # Simple Model için Pseudo-R2 (1 - [Model NLL / Null NLL])
        pseudo_r2_simple = 1 - (nll_simple / nll_null)
        # --- 2. DUAL ALPHA (veya Cemre) MODEL ---
        # k = 3 (Alpha_Pos, Alpha_Neg, Tau)
        params_dual = fit_dual_alpha_map_robust(choices, rewards)
        nll_dual = compute_dual_alpha_log_likelihood(params_dual, choices, rewards)
        bic_dual = 3 * np.log(n_trials) + 2 * nll_dual
        # Dual Alpha Model için Pseudo-R2
        pseudo_r2_dual = 1 - (nll_dual / nll_null)
        # --- WINNER BELİRLEME ---
        # En düşük BIC'e sahip olanı buluyoruz
        bics = {'Null': bic_null, 'Simple': bic_simple, 'DualAlpha': bic_dual}
        winner = min(bics, key=bics.get)
        results.append({
            'denekId': idx,
            'bic_null': bic_null,
            'bic_simple': bic_simple,
            'bic_dual': bic_dual,
            'pseudo_r2_simple': pseudo_r2_simple,
            'pseudo_r2_dual': pseudo_r2_dual,
            'winner': winner
        })
    except Exception as e:
        print(f"Denek {idx} için fitting hatası: {e}")
res_df = pd.DataFrame(results)
merged_df = res_df.merge(subj_list[['task-id', 'group']], left_on='denekId', right_on='task-id', how='inner')


# %% 4. İSTATİSTİK ÖZETİ
print("\n--- GRUP BAZINDA MODEL TERCİHİ ---")
print(merged_df.groupby(['group', 'winner']).size().unstack(fill_value=0))
total_null = merged_df['bic_null'].sum()
total_simple = merged_df['bic_simple'].sum()
print(f"\n--- BÜTÜNCÜL KANIT (Lower is better) ---")
print(f"Null Model Toplam BIC: {total_null:.2f}")
print(f"Simple RL Toplam BIC: {total_simple:.2f}")
print(f"Simple Modeli Null Modele Karşı İyileşme: {(total_null - total_simple):.2f}")
print(f"\n--- ORTALAMA PSEUDO-R2 ---")
print(f"Simple Model Ortalama R2: {merged_df['pseudo_r2_simple'].mean():.3f}")
print(f"Dual Model Ortalama R2: {merged_df['pseudo_r2_dual'].mean():.3f}")

# PAIRED SLOPE GRAPH
plt.figure(figsize=(10, 6))
for i in range(len(merged_df)):
    y1 = merged_df.iloc[i]['bic_simple']
    y2 = merged_df.iloc[i]['bic_dual']
    color = 'green' if y2 < y1 else 'red' # Yeşil = Dual Alpha Modeli BIC'i düşürdü
    plt.plot([0, 1], [y1, y2], marker='o', color=color, alpha=0.4)
plt.xticks([0, 1], ['Simple RL', 'Dual Alpha'])
plt.ylabel('BIC Skoru (Düşük olan daha iyi)')
plt.title(f'Denek Bazlı Model Geçişleri\nToplam İyileşme: {group_improvement:.2f}')
plt.grid(axis='y', linestyle='--', alpha=0.3)
plt.show()

# CUMULATIVE DELTA GRAPH
merged_df = merged_df.sort_values('denekId').reset_index(drop=True)
plt.figure(figsize=(10, 5))
plt.step(range(len(merged_df)), merged_df['delta_bic'].cumsum(), where='mid', color='purple', linewidth=2)
plt.axhline(0, color='black', linestyle='--')
plt.fill_between(range(len(merged_df)), merged_df['delta_bic'].cumsum(), 0, alpha=0.2, color='purple')
plt.title('Kümülatif Model Kanıtı (Cum. Delta BIC)\nYukarı Doğru Gidiş Dual Alpha Modelini Destekler')
plt.xlabel('Katılımcı Sayısı')
plt.ylabel('Kümülatif İyileşme (Delta BIC)')
plt.show()

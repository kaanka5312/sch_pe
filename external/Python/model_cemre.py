import pandas as pd
import numpy as np
import os

# %% 1. YOLLAR VE VERİ YÜKLEME
# Kendi bilgisayar yoluna göre düzenle
PROJECT_FOLDER = 'C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/'
all_subjects = pd.read_csv(os.path.expanduser(PROJECT_FOLDER + 'data/processed/all_subjects.csv'))
subj_list = pd.read_csv(os.path.expanduser(PROJECT_FOLDER + 'data/raw/subjects_list.csv'))
subj_list.columns = subj_list.columns.str.strip()

# %% 2. GRID TANIMLAMALARI
# Cemre Modeli için 3D Grid (alpha0 x epsilon x tau)
# Epsilon: Alpha'nın her başarılı/başarısız turda ne kadar artıp azalacağı
a0_grid = np.linspace(0.001, 1.0, 30)   
eps_grid = np.linspace(0.0, 0.2, 15)    
tau_grid = np.linspace(0.01, 5.0, 30)   

# Basit RL için 2D Grid
alpha_simple_grid = np.linspace(0.001, 1.0, 50)
tau_simple_grid = np.linspace(0.01, 5.0, 50)

# %% 3. MODEL FONKSİYONLARI (20 ve 60 TL yapısına göre)
def compute_cemre_nll(params, choices, rewards):
    a0, epsilon, tau = params
    v, v_keep, alpha_t = 1.0, 1.0, a0 # Başlangıç değerleri (Normalized)
    nll = 0
    eps_val = 1e-10
    
    for t in range(len(choices)):
        # Karar Olasılığı (Softmax)
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_keep)))
        p_choice = prob_invest if choices[t] == 1 else (1 - prob_invest)
        nll -= np.log(p_choice + eps_val)
        
        # Ödül Normalizasyonu (Rewards: 0, 20, 60 -> 0, 2.0, 6.0)
        r_t = rewards[t] / 10.0
        
        if choices[t] == 1:
            # Alpha Güncelleme (Cemre et al., 2022)
            # Eğer Trustee Paylaştıysa alpha artar, El Koyduysa alpha azalır
            if r_t > v_keep:
                alpha_t = np.clip(alpha_t + epsilon, 0.001, 1.0)
            else:
                alpha_t = np.clip(alpha_t - epsilon, 0.001, 1.0)
            
            # Değer Güncelleme
            v = v + alpha_t * (r_t - v)
    return nll

def compute_simple_nll(params, choices, rewards):
    alpha, tau = params
    v, v_keep = 1.0, 1.0
    nll = 0
    eps_val = 1e-10
    for t in range(len(choices)):
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_keep)))
        p_choice = prob_invest if choices[t] == 1 else (1 - prob_invest)
        nll -= np.log(p_choice + eps_val)
        if choices[t] == 1:
            v = v + alpha * (rewards[t]/10.0 - v)
    return nll

# %% 4. GRID SEARCH DÖNGÜSÜ
results = []
n_trials = 60
log_n = np.log(n_trials)

print("BIC bazlı Model Karşılaştırması Başlıyor...")

for idx in all_subjects['denekId'].unique():
    subj_data = all_subjects[all_subjects['denekId'] == idx]
    choices = subj_data['yatirim'].to_numpy()
    rewards = subj_data['kazanc'].to_numpy()
    
    # --- BASİT RL (2 Parametre) ---
    best_nll_s = np.inf
    for a in alpha_simple_grid:
        for t in tau_simple_grid:
            curr = compute_simple_nll([a, t], choices, rewards)
            if curr < best_nll_s: best_nll_s = curr
    bic_simple = 2 * log_n + 2 * best_nll_s
    
    # --- CEMRE MODELİ (3 Parametre) ---
    best_nll_c = np.inf
    best_params_c = (0, 0, 0)
    for a0 in a0_grid:
        for eps in eps_grid:
            for t in tau_grid:
                curr = compute_cemre_nll([a0, eps, t], choices, rewards)
                if curr < best_nll_c:
                    best_nll_c, best_params_c = curr, (a0, eps, t)
    bic_cemre = 3 * log_n + 2 * best_nll_c
    
    results.append({
        'denekId': idx,
        'alpha_0': best_params_c[0],
        'epsilon': best_params_c[1],
        'tau_cemre': best_params_c[2],
        'bic_simple': bic_simple,
        'bic_cemre': bic_cemre,
        'winner': 'Cemre' if bic_cemre < bic_simple else 'Simple'
    })
    print(f"Denek {idx} | Simple BIC: {bic_simple:.2f} | Cemre BIC: {bic_cemre:.2f} | Winner: {results[-1]['winner']}")

# %% 5. GRUPLAMA VE ÖZET
res_df = pd.DataFrame(results)
merged_df = res_df.merge(subj_list[['subj', 'group']], left_on='denekId', right_on='subj')

# Grup Bazlı Model Tercihi
print("\n--- GRUP BAZINDA MODEL TERCİHİ ---")
summary = merged_df.groupby(['group', 'winner']).size().unstack(fill_value=0)
print(summary)

# BIC Medyan Kıyaslaması
print("\n--- BIC MEDYAN DEĞERLERİ ---")
print(merged_df.groupby('group')[['bic_simple', 'bic_cemre']].median())

merged_df.to_csv(os.path.expanduser(PROJECT_FOLDER + 'data/processed/model_selection_results.csv'), index=False)

# %% COMPARING WITH WAIC INSTEAD OF BIC 
import pandas as pd
import numpy as np
import os

# 1. PARAMETRELER VE GRID TANIMLARI (Önceki ızgaralarla aynı)
a0_grid = np.linspace(0.001, 1.0, 30)   
eps_grid = np.linspace(0.0, 0.2, 15)    
tau_grid = np.linspace(0.01, 5.0, 30)

# %% WAIC HESAPLAMA FONKSİYONU
def calculate_waic_from_grid(nll_grid):
    """
    Grid üzerindeki NLL değerlerinden WAIC hesaplar.
    P(theta|D) proportional to exp(-NLL)
    """
    # NLL'leri olasılığa (Likelihood) çevir
    # Sayısal kararlılık için minimum NLL'i çıkarıyoruz (Log-sum-exp trick)
    likelihoods = np.exp(-(nll_grid - np.min(nll_grid)))
    weights = likelihoods / np.sum(likelihoods) # Posterior ağırlıkları
    
    # Ortalama Likelihood (Log Pointwise Predictive Density - lppd)
    # Burada basitleştirilmiş bir grid-weighted lppd hesaplıyoruz
    lppd = np.log(np.sum(weights * np.exp(-(nll_grid - np.min(nll_grid))))) - np.min(nll_grid)
    
    # Etkin Parametre Sayısı (p_waic) - Likelihood varyansına dayalı
    # Modelin ne kadar "esnek" olduğunun bir ölçüsü
    p_waic = np.var(nll_grid) / 2 # Basitleştirilmiş bir yaklaşım
    
    waic = -2 * (lppd - p_waic)
    return waic

# %% 2. ANA DÖNGÜ
results_waic = []

for idx in all_subjects['denekId'].unique():
    subj_data = all_subjects[all_subjects['denekId'] == idx]
    choices = subj_data['yatirim'].to_numpy()
    rewards = subj_data['kazanc'].to_numpy()

    # --- CEMRE MODELİ İÇİN 3D NLL MATRİSİ ---
    nll_matrix_cemre = np.zeros((len(a0_grid), len(eps_grid), len(tau_grid)))
    
    for i, a0 in enumerate(a0_grid):
        for j, eps in enumerate(eps_grid):
            for k, t in enumerate(tau_grid):
                nll_matrix_cemre[i, j, k] = compute_cemre_nll([a0, eps, t], choices, rewards)
    
    waic_cemre = calculate_waic_from_grid(nll_matrix_cemre)

    # --- BASİT RL İÇİN 2D NLL MATRİSİ ---
    nll_matrix_simple = np.zeros((len(alpha_simple_grid), len(tau_simple_grid)))
    for i, a in enumerate(alpha_simple_grid):
        for j, t in enumerate(tau_simple_grid):
            nll_matrix_simple[i, j] = compute_simple_nll([a, t], choices, rewards)
            
    waic_simple = calculate_waic_from_grid(nll_matrix_simple)

    results_waic.append({
        'denekId': idx,
        'waic_simple': waic_simple,
        'waic_cemre': waic_cemre,
        'waic_winner': 'Cemre' if waic_cemre < waic_simple else 'Simple'
    })

waic_df = pd.DataFrame(results_waic)
print(waic_df['waic_winner'].value_counts())

merged_waic = waic_df.merge(subj_list[['task-id', 'group']], left_on='denekId', 
                         right_on='task-id', 
                         how='inner')
print("\n--- GRUP BAZLI ÖZET (Medyan WAIC) ---")
group_summary = merged_waic.groupby('group')[['waic_simple', 'waic_cemre']].median()
print(group_summary)

# Hangi grupta hangi model daha çok seviliyor?
winner_counts = merged_waic.groupby(['group', 'waic_winner']).size().unstack(fill_value=0)
print("\n--- GRUP BAZLI KAZANAN SAYILARI ---")
print(winner_counts)

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# 1. VERİYİ HAZIRLA (waic_df veya model_selection_results içinden)
# Delta hesapla: Pozitif fark = Cemre daha iyi
waic_df['delta_waic'] = waic_df['waic_simple'] - waic_df['waic_cemre']

# 2. GRUP DÜZEYİNDE TOPLAM KANIT (Aggregate Evidence)
total_simple = waic_df['waic_simple'].sum()
total_cemre = waic_df['waic_cemre'].sum()
group_improvement = total_simple - total_cemre

print(f"--- GRUP DÜZEYİNDE TOPLAM ---")
print(f"Simple RL Toplam WAIC: {total_simple:.2f}")
print(f"Cemre Model Toplam WAIC: {total_cemre:.2f}")
print(f"Toplam İyileşme (Evidence Gain): {group_improvement:.2f}")

# 3. GÖRSELLEŞTİRME: PAIRED SLOPE GRAPH
plt.figure(figsize=(10, 6))

# Her katılımcı için bir çizgi
for i in range(len(waic_df)):
    y1 = waic_df.iloc[i]['waic_simple']
    y2 = waic_df.iloc[i]['waic_cemre']
    color = 'green' if y2 < y1 else 'red' # İyileşme varsa yeşil
    plt.plot([0, 1], [y1, y2], marker='o', color=color, alpha=0.5)

plt.xticks([0, 1], ['Simple RL', 'Cemre (Adaptive)'])
plt.ylabel('WAIC Skoru (Düşük olan daha iyi)')
plt.title(f'Denek Bazlı Model Geçişleri (Paired)\nToplam İyileşme: {group_improvement:.2f}')
plt.grid(axis='y', linestyle='--', alpha=0.3)
plt.show()

# 4. KÜMÜLATİF DELTA (Bütüncül Bakış)
waic_df = waic_df.sort_values('denekId').reset_index(drop=True)
plt.figure(figsize=(10, 5))
plt.step(range(len(waic_df)), waic_df['delta_waic'].cumsum(), where='mid', color='blue', linewidth=2)
plt.axhline(0, color='black', linestyle='--')
plt.fill_between(range(len(waic_df)), waic_df['delta_waic'].cumsum(), 0, alpha=0.2, color='blue')
plt.title('Kümülatif Model Kanıtı (Cum. Delta WAIC)')
plt.xlabel('Katılımcı Sayısı')
plt.ylabel('Kümülatif İyileşme')
plt.show()

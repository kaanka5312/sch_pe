# %% LIBRARIES & DATA
import pandas as pd
import numpy as np
from model_functions import simulate_behavior_ppc, plot_ppc, compute_null_log_likelihood, compute_log_likelihood, compute_null_log_likelihood_chance
import matplotlib.pyplot as plt
PROJECT_FOLDER = '~/OneDrive/Belgeler/GitHub/sch_pe/'
#PROJECT_FOLDER = '/Users/kaankeskin/projects/sch_pe/'
all_subjects=pd.read_csv(PROJECT_FOLDER + 'data/processed/all_subjects.csv')
subjects_params = pd.read_csv(PROJECT_FOLDER + 'data/processed/model_parameters.csv')

# %%
idx = 10099
alpha_test = subjects_params.loc[subjects_params['denekId']==idx, 'alpha']
tau_test = subjects_params.loc[subjects_params['denekId']==idx, 'tau']
choices_real = all_subjects.loc[all_subjects['denekId'] == idx, 'yatirim'].to_numpy()
kazanc_real = all_subjects.loc[all_subjects['denekId'] == idx, 'kazanc'].to_numpy()
# 1. Convert to clean arrays (works whether they are Series or Arrays)
choices_clean = np.asarray(choices_real)
kazanc_clean = np.asarray(kazanc_real)
# 2. Grab the first number safely (works for both Series and Arrays)
# Using .item() avoids the KeyError: 0 and the float() conversion issues
alpha_val = alpha_test.item() if hasattr(alpha_test, 'item') else alpha_test[0]
tau_val = tau_test.item() if hasattr(tau_test, 'item') else tau_test[0]

# 2. İçsel Olasılık Hesaplama Fonksiyonu (DÜZELTİLMİŞ)
def get_latent_probabilities(alpha, tau, choices, rewards, v_init=2.0, v_safe=2.0):
    """
    Deneğin parametrelerine göre her trial'daki içsel olasılığı hesaplar.
    Önemli: Sadece yatırım yapılan turlarda V güncellenir.
    """
    n_trials = len(rewards)
    p_trajectories = np.zeros(n_trials)
    v = v_init
    # Ödülleri normalize et (20, 60, 0 -> 2, 6, 0)
    rewards_norm = rewards / 10.0
    for t in range(n_trials):
        # 1. Mevcut V değerine göre yatırım olasılığını kaydet
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        p_trajectories[t] = prob_invest
        # 2. GÜNCELLEME: Sadece denek o tur yatırım yaptıysa (choices[t] == 1) öğrenir
        if choices[t] == 1:
            v = v + alpha * (rewards_norm[t] - v)
    return p_trajectories

# 3. Güncellenmiş PPC Fonksiyonu (DÜZELTİLMİŞ)
def plot_ppc_smooth(actual_choices, rewards, alpha, tau, n_sims=100, idx="Subject"):
    n_trials = len(actual_choices)
    simulated_data = np.zeros((n_sims, n_trials))
    # Simülasyonlar (Mavi alan için)
    for i in range(n_sims):
        # simulate_behavior_ppc fonksiyonunun da v=2.0 mantığıyla çalıştığından emin ol
        simulated_data[i, :] = simulate_behavior_ppc(alpha, tau, rewards)
    # Mavi Alan İçin Yumuşatma (Rolling mean)
    window = 10
    # 'same' modu görsel uyum için iyidir
    sim_rolling = np.array([np.convolve(s, np.ones(window)/window, mode='same') for s in simulated_data])
    # Deneğin İçsel Olasılığı (Pürüzsüz Kırmızı Hat)
    # actual_choices'ı ekledik çünkü öğrenme buna bağlı
    latent_p = get_latent_probabilities(alpha, tau, actual_choices, rewards)
    # Görselleştirme
    plt.figure(figsize=(12, 6))
    mean_sim = np.mean(sim_rolling, axis=0)
    std_sim = np.std(sim_rolling, axis=0)
    trials = np.arange(1, n_trials + 1)
    # Mavi %95 Tahmin Aralığı (Simülasyon Trendi)
    plt.fill_between(trials, mean_sim - 1.96*std_sim, mean_sim + 1.96*std_sim, 
                     color='#3498db', alpha=0.2, label='Model %95 Simülasyon Aralığı')
    plt.plot(trials, mean_sim, color='#2980b9', linestyle='--', alpha=0.6, label='Model Ortalama Trend')
    # Pürüzsüz Kırmızı Çizgi (Deneğin Parametrelerine Göre Modellenmiş Eğilimi)
    plt.plot(trials, latent_p, color='#e74c3c', linewidth=2.5, label='Deneğin İçsel Yatırım Olasılığı (Latent)')
    # Ham Kararlar (Noktalar)
    plt.scatter(trials, actual_choices, color='#c0392b', alpha=0.15, s=15, label='Gerçek Seçimler (0 veya 1)')
    plt.title(f'Posterior Predictive Check - Denek: {idx}\n(Alpha={alpha:.3f}, Tau={tau:.2f})', fontsize=14)
    plt.xlabel('Trial No', fontsize=12)
    plt.ylabel('Yatırım Olasılığı / Oranı', fontsize=12)
    plt.ylim(-0.05, 1.05)
    plt.legend(loc='upper left', frameon=True)
    plt.grid(axis='y', alpha=0.3)
    plt.tight_layout()
    plt.show()

# Çalıştır
plot_ppc_smooth(choices_clean, kazanc_clean, alpha_val, tau_val)

# %% Measuring how much subject learned 
# 1. Get your optimized NLL from your previous fit
rl_nll = compute_log_likelihood([alpha_val, tau_val], choices_clean, kazanc_clean)
# 2. Get the Null NLL
null_nll = compute_null_log_likelihood_chance(choices_clean)
# 3. Calculate McFadden's R-squared
# Note: Use positive Log-Likelihoods (negative of negative)
pseudo_r2 = 1 - ((-rl_nll) / (-null_nll))
print(f"RL Model NLL: {rl_nll:.2f}")
print(f"Null Model NLL: {null_nll:.2f}")
print(f"McFadden's Pseudo R2: {pseudo_r2:.4f}")

if pseudo_r2 < 0.05:
    print("Warning: Model is barely better than a constant guess. Subject may not be learning.")


# Hatanın trial trial dökümü
v = 2.0
v_safe = 2.0
r_norm = kazanc_clean / 10.0
total_nll = 0

print(f"{'Trial':<6} | {'Choice':<6} | {'V':<6} | {'P_Invest':<8} | {'NLL_inc':<8}")
print("-" * 45)

for t in range(len(choices_clean)):
    # Softmax olasılığı
    prob_invest = 1 / (1 + np.exp(-tau_val * (v - v_safe)))
    
    # Gerçekleşen seçimin olasılığı
    p_actual = prob_invest if choices_clean[t] == 1 else (1 - prob_invest)
    nll_inc = -np.log(p_actual + 1e-10)
    total_nll += nll_inc
    
    print(f"{t+1:<6} | {choices_clean[t]:<6.0f} | {v:<6.2f} | {prob_invest:<8.3f} | {nll_inc:<8.2f}")
    
    # Güncelleme
    if choices_clean[t] == 1:
        v = v + alpha_val * (r_norm[t] - v)

print("-" * 45)
print(f"Toplam NLL: {total_nll:.2f}")

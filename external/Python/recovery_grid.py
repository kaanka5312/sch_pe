# PRELUDE 
"""
In this script it named as grid, because it was using grid approximation in the beginning. 
But now it uses MAP.
"""
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from model_functions import compute_log_likelihood, simulate_behavior_ppc , fit_subject_parameters_map_robust
import os
import sys
from scipy.stats import pearsonr
import seaborn as sns
env = os.environ.copy()
env["PYTHONIOENCODING"] = "utf-8"
# %% 1. AYARLAR & GRID TANIMI
#PROJECT_FOLDER = 'C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/'
PROJECT_FOLDER = '/Users/kaankeskin/projects/sch_pe/' 
n_iterations = 30  # Her parametre çifti için kaç simülasyon yapılacağı
n_trials = 300      # Gerçek görevdeki trial sayısı
# Fitting için kullanılan grid (Senin koddaki ile aynı olmalı)
alpha_grid = np.linspace(0.001, 1.0, 100)
tau_grid = np.linspace(0.01, 3.0, 100)
# Test edilecek "Gerçek" (Ground Truth) parametreler
true_alphas = [0.1, 0.3, 0.5, 0.7, 0.9]
true_taus = [1.5, 4.5, 9.0] # Tau'nun farklı seviyelerini de test etmek önemli
#true_taus = [0.5, 1.5, 3.0]
# %% 2. SIMÜLASYON VE RECOVERY DÖNGÜSÜ
recovery_results = []
print(f"Recovery başlıyor: Toplam {len(true_alphas) * len(true_taus) * n_iterations} simülasyon...")
for a_true in true_alphas:
    for t_true in true_taus:
        print(f"Testing True Alpha: {a_true}, True Tau: {t_true}")
        for i in range(n_iterations):
            # A. VERİ ÜRETİMİ (GROUND TRUTH)
            # Yapay bir ödül dizisi oluştur (%70 Paylaşma olasılığı olan 60 trial)
            # Ödüller: 60 TL (Share), 20 TL (Keep), 0 TL (Take-all)
            fake_rewards = np.random.choice([60, 0], size=n_trials, p=[0.7, 0.3])
            # Subject bu ödüllere göre karar veriyor (simulate_behavior_ppc kullanıyoruz)
            sim_choices = simulate_behavior_ppc(alpha=a_true, tau=t_true, rewards=fake_rewards)
            # B. FITTING (ROBUST MAP ESTIMATION)
            try:
                rec_alpha, rec_tau = fit_subject_parameters_map_robust(sim_choices, fake_rewards)
            except Exception as e:
                print(f"Optimization failed on {a_true}, {t_true}, iter {i}: {e}")
                rec_alpha, rec_tau = np.nan, np.nan
            # C. SONUÇLARI KAYDET
            recovery_results.append({
                'true_alpha': a_true,
                'true_tau': t_true,
                'rec_alpha': rec_alpha,
                'rec_tau': rec_tau
            })
recovery_df = pd.DataFrame(recovery_results)

# %% 4. GÖRSELLEŞTİRME VE İSTATİSTİK
alpha_r, _ = pearsonr(recovery_df['true_alpha'], recovery_df['rec_alpha'])
tau_r, _ = pearsonr(recovery_df['true_tau'], recovery_df['rec_tau'])
print("\n--- RECOVERY PERFORMANSI (Pearson r) ---")
print(f"Alpha r: {alpha_r:.3f}")
print(f"Tau r: {tau_r:.3f}")
plt.figure(figsize=(12, 5))
# Alpha Plot
plt.subplot(1, 2, 1)
sns.regplot(data=recovery_df, x='true_alpha', y='rec_alpha', scatter_kws={'alpha':0.3}, color='blue')
plt.plot([0, 1], [0, 1], 'r--', label='Identity Line')
plt.title(f'Alpha Recovery (r={alpha_r:.2f})')
plt.xlabel('True Alpha')
plt.ylabel('Recovered Alpha')
plt.legend()
# Tau Plot
plt.subplot(1, 2, 2)
sns.regplot(data=recovery_df, x='true_tau', y='rec_tau', scatter_kws={'alpha':0.3}, color='green')
plt.plot([0, 3], [0, 3], 'r--', label='Identity Line')
plt.title(f'Tau Recovery (r={tau_r:.2f})')
plt.xlabel('True Tau')
plt.ylabel('Recovered Tau')
plt.legend()
plt.tight_layout()
plt.show()

# ======== Recovery for the same experiment type 80-50-80 distrubition =======
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
from scipy.stats import pearsonr
from model_functions import compute_log_likelihood, simulate_behavior_ppc , fit_subject_parameters_map_robust
import sys
from scipy.stats import pearsonr
import seaborn as sns
# %% 1. CONFIGURATION & PATHS
PROJECT_FOLDER = '/Users/kaankeskin/projects/sch_pe/' 
SAVE_PATH = PROJECT_FOLDER + 'data/processed/parameter_recovery_805080.csv'
# Recovery settings
n_trial = 300
n_iterations = 30  # Number of simulations per parameter pair
true_alphas = [0.1, 0.3, 0.5, 0.7, 0.9]
true_taus = [1.5, 4.5, 9.0] # Tau'nun farklı seviyelerini de test etmek önemli# Grid Search Definition (Matching your main analysis)
alpha_grid = np.linspace(0.001, 1.0, 100)
tau_grid = np.linspace(0.01, 3.0, 100)
# %% 2. CORE FUNCTIONS
def simulate_agent(alpha, tau):
    # 80-50-80 Reward Schedule (60 trials total)
    r1 = np.random.choice([60, 0], size=n_trial//3, p=[0.8, 0.2])
    r2 = np.random.choice([60, 0], size=n_trial//3, p=[0.5, 0.5])
    r3 = np.random.choice([60, 0], size=n_trial//3, p=[0.8, 0.2])
    rewards = np.concatenate([r1, r2, r3])
    choices = np.zeros(n_trial)
    v = 20.0/60.0 
    v_safe = 20.0/60.0
    for t in range(n_trial):
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        choice = 1 if np.random.rand() < prob_invest else 0
        choices[t] = choice
        if choice == 1:
            v = v + alpha * ((rewards[t]/60.0) - v)
    return choices, rewards

# %% 3. EXECUTION LOOP
recovery_data = []
print(f"Starting Recovery for 80-50-80 Schedule...")
for a_true in true_alphas:
    for t_true in true_taus:
        print(f"Testing True Alpha: {a_true}, True Tau: {t_true}")
        for i in range(n_iterations):
            # Generate synthetic data
            c_sim, r_sim = simulate_agent(a_true, t_true)
            # B. FITTING (ROBUST MAP ESTIMATION)
            try:
                rec_alpha, rec_tau = fit_subject_parameters_map_robust(c_sim, r_sim)
            except Exception as e:
                print(f"Optimization failed on {a_true}, {t_true}, iter {i}: {e}")
                rec_alpha, rec_tau = np.nan, np.nan
            # C. SONUÇLARI KAYDET
            recovery_data.append({
                'true_alpha': a_true,
                'true_tau': t_true,
                'rec_alpha': rec_alpha,
                'rec_tau': rec_tau
            })

# Create DataFrame
recovery_df = pd.DataFrame(recovery_data, columns=['true_alpha', 'true_tau', 'rec_alpha', 'rec_tau'])
# Save results
if not os.path.exists(os.path.dirname(SAVE_PATH)):
    os.makedirs(os.path.dirname(SAVE_PATH))
recovery_df.to_csv(SAVE_PATH, index=False)
# ======== Plotting and Statistical Reporting ######
recovery_df = pd.read_csv(SAVE_PATH)
# %% 4. GÖRSELLEŞTİRME VE İSTATİSTİK
alpha_r, _ = pearsonr(recovery_df['true_alpha'], recovery_df['rec_alpha'])
tau_r, _ = pearsonr(recovery_df['true_tau'], recovery_df['rec_tau'])
print("\n--- RECOVERY PERFORMANSI (Pearson r) ---")
print(f"Alpha r: {alpha_r:.3f}")
print(f"Tau r: {tau_r:.3f}")
plt.figure(figsize=(12, 5))
# Alpha Plot
plt.subplot(1, 2, 1)
sns.regplot(data=recovery_df, x='true_alpha', y='rec_alpha', scatter_kws={'alpha':0.3}, color='blue')
plt.plot([0, 1], [0, 1], 'r--', label='Identity Line')
plt.title(f'Alpha Recovery (r={alpha_r:.2f})')
plt.xlabel('True Alpha')
plt.ylabel('Recovered Alpha')
plt.legend()
# Tau Plot
plt.subplot(1, 2, 2)
sns.regplot(data=recovery_df, x='true_tau', y='rec_tau', scatter_kws={'alpha':0.3}, color='green')
plt.plot([0, 10], [0, 10], 'r--', label='Identity Line')
plt.title(f'Tau Recovery (r={tau_r:.2f})')
plt.xlabel('True Tau')
plt.ylabel('Recovered Tau')
plt.legend()
plt.tight_layout()
plt.show()

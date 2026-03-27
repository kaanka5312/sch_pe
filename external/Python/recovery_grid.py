import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from model_functions import compute_log_likelihood, simulate_behavior_ppc
import os
import sys
env = os.environ.copy()
env["PYTHONIOENCODING"] = "utf-8"
# %% 1. AYARLAR & GRID TANIMI
PROJECT_FOLDER = 'C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/'
n_iterations = 30  # Her parametre çifti için kaç simülasyon yapılacağı
n_trials = 60      # Gerçek görevdeki trial sayısı
# Fitting için kullanılan grid (Senin koddaki ile aynı olmalı)
alpha_grid = np.linspace(0.001, 1.0, 100)
tau_grid = np.linspace(0.01, 5.0, 100)
# Test edilecek "Gerçek" (Ground Truth) parametreler
true_alphas = [0.1, 0.3, 0.5, 0.7, 0.9]
true_taus = [0.5, 1.5, 3.0] # Tau'nun farklı seviyelerini de test etmek önemli
recovery_results = []

# %% 2. SIMÜLASYON VE RECOVERY DÖNGÜSÜ
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
            # B. FITTING (BRUTE-FORCE GRID SEARCH)
            best_nll = np.inf
            recovered_params = (0, 0)
            # Senin grid search mantığın
            for a_fit in alpha_grid:
                for t_fit in tau_grid:
                    # compute_log_likelihood içinde rewards / 20.0 yapıldığına emin ol!
                    current_nll = compute_log_likelihood([a_fit, t_fit], sim_choices, fake_rewards)
                    if current_nll < best_nll:
                        best_nll = current_nll
                        recovered_params = (a_fit, t_fit)
            # C. SONUÇLARI KAYDET
            recovery_results.append({
                'true_alpha': a_true,
                'true_tau': t_true,
                'rec_alpha': recovered_params[0],
                'rec_tau': recovered_params[1]
            })
recovery_df = pd.DataFrame(recovery_results)

# %% 3. GÖRSELLEŞTİRME (ALPHA RECOVERY)
plt.figure(figsize=(12, 5))
# Alpha Plot
plt.subplot(1, 2, 1)
plt.scatter(recovery_df['true_alpha'], recovery_df['rec_alpha'], alpha=0.3, color='blue')
plt.plot([0, 1], [0, 1], 'r--', label='Identity Line (Perfect Recovery)')
plt.title(f'Alpha Recovery (Trials={n_trials})')
plt.xlabel('True Alpha')
plt.ylabel('Recovered Alpha')
plt.legend()
# Tau Plot
plt.subplot(1, 2, 2)
plt.scatter(recovery_df['true_tau'], recovery_df['rec_tau'], alpha=0.3, color='green')
plt.plot([0, 5], [0, 5], 'r--', label='Identity Line')
plt.title(f'Tau Recovery (Trials={n_trials})')
plt.xlabel('True Tau')
plt.ylabel('Recovered Tau')
plt.legend()
plt.tight_layout()
#plt.savefig(PROJECT_FOLDER + 'results/figures/parameter_recovery_grid.png')
plt.show()

# Korelasyonları Yazdır
print("\n--- RECOVERY PERFORMANSI (Pearson r) ---")
print(f"Alpha r: {recovery_df['true_alpha'].corr(recovery_df['rec_alpha']):.3f}")
print(f"Tau r: {recovery_df['true_tau'].corr(recovery_df['rec_tau']):.3f}")

# Hızlıca bir korelasyon grafiği görmek istersen:
import seaborn as sns
plt.figure(figsize=(6,6))
sns.regplot(data=recovery_df, x='true_alpha', y='rec_alpha', scatter_kws={'alpha':0.3})
plt.plot([0, 1], [0, 1], 'r--') # İdeal çizgi
plt.title(f'Alpha Recovery Performance (r={recovery_df["true_alpha"].corr(recovery_df["rec_alpha"]):.2f})')
plt.show()

# ======== Recovery for the same experiment type 80-50-80 distrubition =======
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
from scipy.stats import pearsonr

# %% 1. CONFIGURATION & PATHS
PROJECT_FOLDER = 'C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/' # Update if needed
SAVE_PATH = PROJECT_FOLDER + 'data/processed/parameter_recovery_805080.csv'

# Recovery settings
n_iterations = 30  # Number of simulations per parameter pair
true_alphas = [0.1, 0.3, 0.5, 0.7, 0.9]
true_taus = [0.5, 1.5, 3.0]

# Grid Search Definition (Matching your main analysis)
alpha_grid = np.linspace(0.001, 1.0, 100)
tau_grid = np.linspace(0.01, 5.0, 100)

# %% 2. CORE FUNCTIONS
def simulate_agent(alpha, tau):
    # 80-50-80 Reward Schedule (60 trials total)
    r1 = np.random.choice([60, 0], size=20, p=[0.8, 0.2])
    r2 = np.random.choice([60, 0], size=20, p=[0.5, 0.5])
    r3 = np.random.choice([60, 0], size=20, p=[0.8, 0.2])
    rewards = np.concatenate([r1, r2, r3])
    
    choices = np.zeros(60)
    v = 1.0
    v_safe = 1.0
    
    for t in range(60):
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        choice = 1 if np.random.rand() < prob_invest else 0
        choices[t] = choice
        
        if choice == 1:
            v = v + alpha * ((rewards[t]/20.0) - v)
            
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
            
            # 100x100 Grid Search Recovery
            best_nll = np.inf
            rec_alpha, rec_tau = 0, 0
            
            for a_fit in alpha_grid:
                for t_fit in tau_grid:
                    nll = compute_log_likelihood([a_fit, t_fit], c_sim, r_sim)
                    if nll < best_nll:
                        best_nll = nll
                        rec_alpha, rec_tau = a_fit, t_fit
            
            recovery_data.append([a_true, t_true, rec_alpha, rec_tau])

# Create DataFrame
recovery_df = pd.DataFrame(recovery_data, columns=['true_alpha', 'true_tau', 'rec_alpha', 'rec_tau'])


# Save results
if not os.path.exists(os.path.dirname(SAVE_PATH)):
    os.makedirs(os.path.dirname(SAVE_PATH))
recovery_df.to_csv(SAVE_PATH, index=False)

# ======== Plotting and Statistical Reporting ######
from scipy.stats import pearsonr
#recovery_df = pd.read_csv(SAVE_PATH)
recovery_df = pd.read_csv(PROJECT_FOLDER + 'data/processed/parameter_recovery_results.csv')

# %% 4. RESULTS & VISUALIZATION
alpha_r, _ = pearsonr(recovery_df['true_alpha'], recovery_df['rec_alpha'])
tau_r, _ = pearsonr(recovery_df['true_tau'], recovery_df['rec_tau'])
print(f"\nRecovery Results:")
print(f"Alpha Pearson r: {alpha_r:.3f}")
print(f"Tau Pearson r: {tau_r:.3f}")

# Plotting
plt.figure(figsize=(12, 5))
plt.subplot(1, 2, 1)
plt.scatter(recovery_df['true_alpha'], recovery_df['rec_alpha'], alpha=0.3, color='blue')
plt.plot([0, 1], [0, 1], 'r--', label='Identity')
plt.title(f'Alpha Recovery (r={alpha_r:.2f})')
plt.xlabel('True Alpha') ; plt.ylabel('Recovered Alpha')
# Sub2
plt.subplot(1, 2, 2)
plt.scatter(recovery_df['true_tau'], recovery_df['rec_tau'], alpha=0.3, color='green')
plt.plot([0, 5], [0, 5], 'r--', label='Identity')
plt.title(f'Tau Recovery (r={tau_r:.2f})')
plt.xlabel('True Tau') ; plt.ylabel('Recovered Tau')
plt.tight_layout()
plt.show()

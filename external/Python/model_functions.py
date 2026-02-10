# This script includes in functions 
import numpy as np
from scipy.optimize import minimize
import matplotlib.pyplot as plt
from scipy.stats import beta, gamma

# Prior Parametreleri (Literatürde sık kullanılan değerler)
# Alpha için Beta(1.1, 1.1) -> 0 ile 1 arasını korur, uçlara çok sert gitmez.
# Tau için Gamma(shape=2, scale=3) -> Zirvesi 3-4 civarıdır, 10'a gitmeyi cezalandırır.
def compute_neg_log_posterior(params, choices, rewards):
    alpha, tau = params
    
    # 1. Standart Negative Log-Likelihood hesapla (Senin mevcut fonksiyonun)
    neg_ll = compute_log_likelihood(params, choices, rewards)
    
    # 2. Log-Prior hesapla (Parametrelerin "cezası")
    # Alpha [0,1] aralığında olmalı
    prior_alpha = beta.logpdf(alpha, 1.1, 1.1)
    
    # Tau pozitif olmalı ve çok büyük değerler cezalandırılmalı
    prior_tau = gamma.logpdf(tau, 2, scale=1)
    
    # Toplam Hata = Neg_LL - (Log_Priors)
    # (Eksi olmasının sebebi minimize ettiğimiz için; olasılığı maksimize etmek, negatifini minimize etmektir)
    return neg_ll - (prior_alpha + prior_tau)

def fit_subject_parameters_map(choices, rewards):
    """Alpha ve Tau'yu MAP estimation kullanarak fit eder."""
    # Bounds: Alpha [0, 1], Tau [0.001, 20]
    # Not: MAP kullandığımızda Tau sınırı 10 veya 20 olabilir, 
    # çünkü prior onu zaten ortalarda tutmaya çalışacak.
    res = minimize(compute_neg_log_posterior, x0=[0.2, 2.0], 
                   args=(choices, rewards), 
                   bounds=[(1e-5, 1), (0.01, 20.0)], method='L-BFGS-B')
    
    return res.x # [alpha_map, tau_map]
"""
# This was the old Likelihood. 
def compute_log_likelihood(params, choices, rewards):
   #j Implements the Sigmoid Softmax and Rescorla-Wagner update.
   # Returns Negative Log-Likelihood for optimization.
    alpha, tau = params
    v = 20       # Initial Expected Value (Neutral)
    v_safe = 20   # Value of the 'Not Invest' choice
    
    neg_ll = 0
    eps = 1e-10   # Stability constant
    
    for t in range(len(choices)):
        # 1. Softmax (Sigmoid) function from RL.pdf
        # P(Invest) = 1 / (1 + exp(-tau * (V_invest - V_safe)))
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        
        # 2. Likelihood of the actual observed choice
        p_choice = prob_invest if choices[t] == 1 else (1 - prob_invest)
        neg_ll -= np.log(p_choice + eps)
        
        # 3. Learning Update (Prediction Error)
        delta = rewards[t] - v
        v = v + alpha * delta
        
    return neg_ll
"""
def compute_log_likelihood(params, choices, rewards):
    alpha, tau = params
    # Önemli: Ham ödülleri (20, 60, 0) burada bir kez normalize ediyoruz
    r_norm = rewards / 10.0
    v_safe = 2.0   # 20 TL / 10
    v = 2.0        # Başlangıç (Nötr)
    
    neg_ll = 0
    eps = 1e-10
    
    for t in range(len(choices)):
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        p_choice = prob_invest if choices[t] == 1 else (1 - prob_invest)
        neg_ll -= np.log(p_choice + eps)
        
        if choices[t] == 1:
            v = v + alpha * (r_norm[t] - v)
    return neg_ll

def fit_subject_parameters(choices, rewards):
    """Fits Alpha and Tau using Maximum Likelihood Estimation."""
    # Bounds: Alpha [0, 1], Tau [0, 20]
    res = minimize(compute_log_likelihood, x0=[0.5, 1.0], 
                   args=(choices, rewards), 
                   bounds=[(0, 1), (0.001, 1)], method='L-BFGS-B')
    return res.x # returns [alpha, tau]

def fit_subject_parameters_robust(choices, rewards):
    best_res = None
    # Farklı Tau başlangıç noktalarıyla dene: 0.1, 1.0, 10.0
    for start_tau in [0.1, 1.0, 5.0]:
        res = minimize(compute_log_likelihood, 
                       x0=[0.2, start_tau], # Alpha 0.2, Tau değişken
                       args=(choices, rewards), 
                       bounds=[(0, 1), (0.001, 10.0)], 
                       method='L-BFGS-B')
        
        if best_res is None or res.fun < best_res.fun:
            best_res = res
            
    return best_res.x

def generate_rl_signals(alpha, choices, rewards):
    """Fitted alpha ile trial-by-trial PE ve Value sinyallerini üretir."""
    v = 2.0         # NORMALIZE: 20 yerine 2.0
    r_norm = rewards / 10.0
    pe_history = []
    v_history = []
    
    for t in range(len(choices)):
        v_history.append(v)            # Seçim öncesi beklenen değer
        delta = r_norm[t] - v          # Normalize PE
        pe_history.append(delta)
        
        # KRİTİK: Sadece yatırım yapıldığında öğrenme gerçekleşir
        if choices[t] == 1:
            v = v + alpha * delta
        # Pas geçilirse v bir sonraki trial için aynı kalır
            
    return np.array(pe_history), np.array(v_history)

def simulate_behavior_recovery(alpha, tau, num_trials=60):
    # Simülasyon kendi içinde normalize (2.0) çalışır ama dışarıya 
    # gerçek görevdeki gibi ham (20, 60, 0) ödülleri verir.
    v = 2.0
    v_safe = 2.0
    choices = []
    rewards_raw = []
    
    for t in range(num_trials):
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        choice = 1 if np.random.rand() < prob_invest else 0
        
        if choice == 1:
            # Manuskript: %70 Trust (60 TL), %30 No-Trust (0 TL)
            reward = 60 if np.random.rand() < 0.7 else 0
        else:
            reward = 20 # Keep: 20 TL
            
        choices.append(choice)
        rewards_raw.append(reward)
        
        if choice == 1:
            v = v + alpha * ((reward/10.0) - v)
            
    return np.array(choices), np.array(rewards_raw)

def simulate_behavior_ppc(alpha, tau, rewards, v_init=2.0, v_safe=2.0):
    """Subject'in parametreleri ile normalize ölçekte yapay kararlar üretir."""
    n_trials = len(rewards)
    r_norm = rewards / 10.0
    choices = np.zeros(n_trials)
    v = v_init
    
    for t in range(n_trials):
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        choices[t] = np.random.choice([1, 0], p=[prob_invest, 1 - prob_invest])
        
        # KRİTİK: Sadece yatırım yapıldığında güncelleme
        if choices[t] == 1:
            v = v + alpha * (r_norm[t] - v)
            
    return choices

def plot_ppc(actual_choices, rewards, alpha, tau, n_sims=100):
    """Gerçek davranış ile simülasyonu kıyaslar."""
    simulated_data = np.zeros((n_sims, len(actual_choices)))
    
    for i in range(n_sims):
        simulated_data[i, :] = simulate_behavior_ppc(alpha, tau, rewards)
        
    # Öğrenme eğrisini hesapla (Rolling mean)
    window = 10
    actual_rolling = np.convolve(actual_choices, np.ones(window)/window, mode='valid')
    sim_rolling = np.array([np.convolve(s, np.ones(window)/window, mode='valid') for s in simulated_data])
    
    # Görselleştirme
    plt.figure(figsize=(10, 5))
    mean_sim = np.mean(sim_rolling, axis=0)
    std_sim = np.std(sim_rolling, axis=0)
    trials = np.arange(window, len(actual_choices) + 1)
    
    # 95% Güven Aralığı (Modelin tahmin alanı)
    plt.fill_between(trials, mean_sim - 1.96*std_sim, mean_sim + 1.96*std_sim, color='blue', alpha=0.2, label='Model %95 Tahmin Aralığı')
    plt.plot(trials, mean_sim, color='blue', label='Model Ortalama Davranış')
    
    # Gerçek Denek Davranışı
    plt.plot(trials, actual_rolling, color='red', linewidth=2, label='Gerçek Denek Davranışı')
    # Mevcut plot kodunun altına ekle
    plt.scatter(range(len(actual_choices)), actual_choices, color='red', alpha=0.1, s=10)
    
    plt.title(f'Posterior Predictive Check (Alpha={alpha:.2f}, Tau={tau:.2f})')
    plt.xlabel('Trial')
    plt.ylabel('Yatırım Oranı (Rolling Mean)')
    plt.legend()
    plt.show()

def compute_null_log_likelihood(choices):
    # The best estimate for a constant probability is the mean of choices
    # Computing null Likelihood to compare if subject learning doing any better
    p_mean = np.mean(choices)
    eps = 1e-10
    
    # Calculate log-likelihood for constant p
    # LL = sum(choices * log(p) + (1-choices) * log(1-p))
    null_ll = np.sum(choices * np.log(p_mean + eps) + 
                     (1 - choices) * np.log(1 - p_mean + eps))
    
    return -null_ll # Return Negative LL to match your other function

def compute_null_log_likelihood_chance(choices):
    # Denek her zaman yazı-tura atıyormuş gibi (p=0.5)
    n_trials = len(choices)
    # LL = n_trials * log(0.5)
    null_ll = n_trials * np.log(0.5)
    return -null_ll

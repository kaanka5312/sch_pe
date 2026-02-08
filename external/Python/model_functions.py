# This script includes in functions 
import numpy as np
from scipy.optimize import minimize
import matplotlib.pyplot as plt
def compute_log_likelihood(params, choices, rewards):
    """
    Implements the Sigmoid Softmax and Rescorla-Wagner update.
    Returns Negative Log-Likelihood for optimization.
    """
    alpha, tau = params
    v = 0.5       # Initial Expected Value (Neutral)
    v_safe = 10   # Value of the 'Not Invest' choice
    
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

def fit_subject_parameters(choices, rewards):
    """Fits Alpha and Tau using Maximum Likelihood Estimation."""
    # Bounds: Alpha [0, 1], Tau [0, 20]
    res = minimize(compute_log_likelihood, x0=[0.5, 1.0], 
                   args=(choices, rewards), 
                   bounds=[(0, 1), (0.001, 20)], method='L-BFGS-B')
    return res.x # returns [alpha, tau]

def generate_rl_signals(alpha, choices, rewards):
    """Generates trial-by-trial PE and Value signals using best-fit alpha."""
    v = 0.5
    pe_history = []
    v_history = []
    
    for t in range(len(choices)):
        v_history.append(v)     # Expected Value BEFORE outcome
        delta = rewards[t] - v  # Signed Prediction Error
        pe_history.append(delta)
        v = v + alpha * delta   # Update for next trial
        
    return np.array(pe_history), np.array(v_history)


def simulate_behavior_recovery(alpha, tau, num_trials=60):
    """Simulates a subject's choices and rewards."""
    v = 0.5
    v_safe = 20
    choices = []
    rewards = []
    
    for t in range(num_trials):
        # Softmax selection
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        choice = 1 if np.random.rand() < prob_invest else 0
        
        # Reward logic (matches your Task: 80% win, etc.)
        if choice == 1:
            # Simplified: 70% chance of 30TL, 30% chance of 0TL
            reward = 60 if np.random.rand() < 0.7 else 0
        else:
            reward = 20
            
        choices.append(choice)
        rewards.append(reward)
        v = v + alpha * (reward - v)
        
    return np.array(choices), np.array(rewards)

def simulate_behavior_ppc(alpha, tau, rewards, v_init=0.5, v_safe=20):
    """Subject'in parametreleri ile yapay kararlar üretir."""
    n_trials = len(rewards)
    choices = np.zeros(n_trials)
    v = v_init
    
    for t in range(n_trials):
        # Softmax: Yatırım yapma olasılığını hesapla
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        # Olasılığa göre rastgele bir seçim yap (0 veya 1)
        choices[t] = np.random.choice([1, 0], p=[prob_invest, 1 - prob_invest])
        
        # Rescorla-Wagner güncellemesi (Gerçek ödülü kullanarak)
        v = v + alpha * (rewards[t] - v)
        
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

import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize
from model_functions import compute_log_likelihood # Import from our previous script

def simulate_behavior(alpha, tau, num_trials=60):
    """Simulates a subject's choices and rewards."""
    v = 0.5
    v_safe = 10
    choices = []
    rewards = []
    
    for t in range(num_trials):
        # Softmax selection
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        choice = 1 if np.random.rand() < prob_invest else 0
        
        # Reward logic (matches your Task: 80% win, etc.)
        if choice == 1:
            # Simplified: 70% chance of 30TL, 30% chance of 0TL
            reward = 30 if np.random.rand() < 0.7 else 0
        else:
            reward = 10
            
        choices.append(choice)
        rewards.append(reward)
        v = v + alpha * (reward - v)
        
    return np.array(choices), np.array(rewards)

# --- Recovery Test ---
true_alphas = np.linspace(0.1, 0.9, 10)
recovered_alphas = []

for a_true in true_alphas:
    c, r = simulate_behavior(alpha=a_true, tau=2.0)
    # Fit the simulated data
    res = minimize(compute_log_likelihood, x0=[0.5, 1.0], args=(c, r),
                   bounds=[(0, 1), (0.01, 20)], method='L-BFGS-B')
    recovered_alphas.append(res.x[0])

# Plot for Referee 2
plt.figure(figsize=(6,6))
plt.scatter(true_alphas, recovered_alphas, color='blue')
plt.plot([0, 1], [0, 1], 'r--') # Identity line
plt.xlabel('True Alpha')
plt.ylabel('Recovered Alpha')
plt.title('Parameter Recovery Validation')
plt.show()

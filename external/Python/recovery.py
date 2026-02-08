import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize
from model_functions import compute_log_likelihood,simulate_behavior_recovery # Import from our previous script

# --- Recovery Test ---
true_alphas = np.linspace(0.1, 0.9, 10)
n_iterations = 100  # Number of repeats per alpha value

# We will store results in lists to plot later
all_true = []
all_recovered = []

for a_true in true_alphas:
    print(f"Testing Alpha: {a_true:.2f}") # Progress tracker
    for i in range(n_iterations):
        # 1. Simulate behavior
        c, r = simulate_behavior_recovery(alpha=a_true, tau=2.0)
        
        # 2. Fit the simulated data
        res = minimize(compute_log_likelihood, x0=[0.5, 1.0], args=(c, r),
                       bounds=[(0, 1), (0.01, 20)], method='L-BFGS-B')
        
        # 3. Store both the ground truth and the result
        all_true.append(a_true)
        all_recovered.append(res.x[0])

# --- Plotting ---
plt.figure(figsize=(7,7))

# Use 'alpha' (transparency) so you can see where points overlap
plt.scatter(all_true, all_recovered, color='blue', alpha=0.1, label='Simulated Iterations')

# Optional: Plot the mean recovered value for each linspace point
mean_recovered = [np.mean(np.array(all_recovered)[np.array(all_true) == a]) for a in true_alphas]
plt.plot(true_alphas, mean_recovered, 'o-', color='black', label='Mean Recovery')

plt.plot([0, 1], [0, 1], 'r--', linewidth=2, label='Perfect Recovery') # Identity line
plt.xlabel('True Alpha')
plt.ylabel('Recovered Alpha')
plt.title(f'Parameter Recovery (n={n_iterations} per point)')
plt.legend()
plt.grid(True, linestyle=':', alpha=0.6)
plt.show()

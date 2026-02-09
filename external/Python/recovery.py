import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize
from model_functions import compute_log_likelihood, simulate_behavior_recovery

true_alphas = np.linspace(0.1, 0.9, 10)
n_iterations = 50 
n_trials = 200

all_true = []
all_recovered = []

for a_true in true_alphas:
    print(f"Testing Alpha: {a_true:.2f}")
    for i in range(n_iterations):
        # 1. Ham ödülleri (20, 60, 0) üreten simülasyon
        c, r = simulate_behavior_recovery(alpha=a_true, tau=2.0, num_trials=n_trials)
        
        # 2. Likelihood içinde r'yi 10'a bölecek, yani denge kurulacak
        res = minimize(compute_log_likelihood, x0=[0.2, 1.0], args=(c, r),
                       bounds=[(1e-5, 1), (0.01, 1)], method='L-BFGS-B')
        
        all_true.append(a_true)
        all_recovered.append(res.x[0])

# Görselleştirme (Scatter ve Mean Recovery)
plt.figure(figsize=(8,8))
plt.scatter(all_true, all_recovered, color='blue', alpha=0.1)
mean_rec = [np.mean(np.array(all_recovered)[np.array(all_true) == a]) for a in true_alphas]
plt.plot(true_alphas, mean_rec, 'o-', color='black', label='Mean Recovery')
plt.plot([0, 1], [0, 1], 'r--', label='Identity Line')
plt.title("Hata Düzeltilmiş Parameter Recovery")
plt.xlabel("True Alpha")
plt.ylabel("Recovered Alpha")
plt.legend()
plt.show()

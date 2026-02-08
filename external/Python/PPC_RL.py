import pandas as pd
import numpy as np
from model_functions import simulate_behavior_ppc, plot_ppc, compute_null_log_likelihood, compute_log_likelihood
import matplotlib as plt

all_subjects=pd.read_csv('/Users/kaankeskin/projects/sch_pe/data/processed/all_subjects.csv')
subjects_params = pd.read_csv('/Users/kaankeskin/projects/sch_pe/data/processed/model_parameters.csv')

# %%
idx = 10077
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
# 3. Run the plot
plot_ppc(choices_clean, kazanc_clean, alpha_val, tau_val, n_sims=100)


# %% Measuring how much subject learned 
# 1. Get your optimized NLL from your previous fit
rl_nll = compute_log_likelihood([alpha_val, tau_val], choices_clean, kazanc_clean)
# 2. Get the Null NLL
null_nll = compute_null_log_likelihood(choices_clean)
# 3. Calculate McFadden's R-squared
# Note: Use positive Log-Likelihoods (negative of negative)
pseudo_r2 = 1 - ((-rl_nll) / (-null_nll))
print(f"RL Model NLL: {rl_nll:.2f}")
print(f"Null Model NLL: {null_nll:.2f}")
print(f"McFadden's Pseudo R2: {pseudo_r2:.4f}")

if pseudo_r2 < 0.05:
    print("Warning: Model is barely better than a constant guess. Subject may not be learning.")




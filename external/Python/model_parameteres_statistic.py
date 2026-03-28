# %% LIBRARIES
import pandas as pd
import numpy as np
import statsmodels.formula.api as smf
import matplotlib.pyplot as plt
import seaborn as sns
# %% 1. LOAD DATA
params = pd.read_csv("../../data/processed/final_group_parameters.csv")
subjects = pd.read_csv("../../data/raw/subjects_list.csv")
# Clean column names (removes hidden spaces)
subjects.columns = subjects.columns.str.strip()
params.columns = params.columns.str.strip()
# %% 2. PRE-PROCESSING & EXCLUSION
exclude_ids = [9, 44, 77]
# Merge data (Inner join)
# Adjust left_on/right_on if your column names differ slightly
df_clean = pd.merge(params, subjects, left_on="denekId", right_on="task-id", how="inner")
# Exclude specific subjects
df_clean = df_clean[~df_clean['denekId'].isin(exclude_ids)].copy()
# Rename columns (adjusting for pandas merge suffixes if needed)
df_clean = df_clean.rename(columns={
    'group_x': 'group',  # Update this if your column was named group.x
    'Age': 'age',
    'Sex': 'sex'
})

# Helper function to safely strip spaces and convert to numeric (Fixes the " 27" string issue!)
def safe_numeric(col):
    if df_clean[col].dtype == 'object':
        return pd.to_numeric(df_clean[col].str.strip(), errors='coerce')
    return pd.to_numeric(df_clean[col], errors='coerce')
# Map factors (Assumes 0=HC, 1=SZ based on your earlier scripts. Adjust if needed!)
df_clean['group'] = df_clean['group'].replace({0: 'HC', 1: 'SZ'})
df_clean['sex'] = df_clean['sex'].replace({1: 'F', 2: 'M'})
# Numeric conversions and Log-transforms
df_clean['tau'] = safe_numeric('tau')
df_clean['log_tau'] = np.log(df_clean['tau'])
df_clean['DOI'] = safe_numeric('DoI')
# Z-score Scaling function
def scale_z(col_name):
    num_col = safe_numeric(col_name)
    return (num_col - num_col.mean()) / num_col.std()
df_clean['Age_z'] = scale_z('age')
df_clean['AP_z'] = scale_z('ap')
df_clean['education_z'] = scale_z('education')
df_clean['PANSS_neg_z'] = scale_z('PANSS-Negative')
df_clean['PANSS_pos_z'] = scale_z('PANSS-Positive')

# %% 3. MODEL 1: GROUP DIFFERENCES
# statsmodels automatically recognizes 'Group' as categorical because it contains strings
fit_alpha_group = smf.ols('alpha ~ group + education_z + Age_z', data=df_clean).fit()
fit_tau_group = smf.ols('log_tau ~ group + education_z + Age_z', data=df_clean).fit()
print("--- Group Differences: Alpha ---")
print(fit_alpha_group.summary())
print("\n--- Group Differences: Tau ---")
print(fit_tau_group.summary())

# %% 4. MODEL 2: CLINICAL CONFOUNDING (SZ ONLY)
sz_only = df_clean[df_clean['group'] == 'SZ'].copy()
fit_alpha_clinical = smf.ols('alpha ~ DOI + Age_z + sex + PANSS_pos_z', data=sz_only).fit()
fit_tau_clinical = smf.ols('log_tau ~ DOI + Age_z + sex + PANSS_pos_z', data=sz_only).fit()
print("\n--- SZ Clinical Correlates: Alpha ---")
print(fit_alpha_clinical.summary())
print(fit_tau_clinical.summary())


# %% 5. VISUALIZATION (Equivalent to ggplot2)
fig, axes = plt.subplots(1, 2, figsize=(12, 5))
# Plot 1: Alpha
# fliersize=0 removes the standard boxplot outlier dots so they don't overlap with the jitter
sns.boxplot(x='group', y='alpha', data=df_clean, ax=axes[0], palette='Set2', boxprops={'alpha': 0.5}, fliersize=0)
sns.stripplot(x='group', y='alpha', data=df_clean, ax=axes[0], color='black', alpha=0.6, jitter=True)
axes[0].set_title('Learning Rate (Alpha)')
axes[0].set_ylabel(r'$\alpha$') # Supports LaTeX formatting!
# Plot 2: Tau
sns.boxplot(x='Group', y='tau', data=df_clean, ax=axes[1], palette='Set2', boxprops={'alpha': 0.5}, fliersize=0)
sns.stripplot(x='Group', y='tau', data=df_clean, ax=axes[1], color='black', alpha=0.6, jitter=True)
axes[1].set_yscale('log') # Log scale equivalent to scale_y_log10()
axes[1].set_title('Decision Noise (Tau)')
axes[1].set_ylabel('Tau (Log Scale)')
plt.tight_layout()
plt.show()

from scipy.stats import permutation_test
import numpy as np

# %% PERMUTATION TEST: LOG_TAU (HC vs SZ)
# 1. Isolate the log_tau arrays for both groups
hc_log_tau = df_clean[df_clean['group'] == 'HC']['log_tau'].values
sz_log_tau = df_clean[df_clean['group'] == 'SZ']['log_tau'].values
# 2. Define the test statistic (Difference in means)
def diff_in_means(x, y):
    return np.mean(x) - np.mean(y)
# 3. Run the Permutation Test (10,000 resamples for high stability)
perm_res = permutation_test(
    (hc_log_tau, sz_log_tau), 
    statistic=diff_in_means, 
    permutation_type='independent', 
    n_resamples=10000, 
    alternative='two-sided'
)
# 4. Print the Results cleanly
print("\n--- PERMUTATION TEST: LOG_TAU ---")
print(f"HC Mean (log_tau): {np.mean(hc_log_tau):.4f}")
print(f"SZ Mean (log_tau): {np.mean(sz_log_tau):.4f}")
print(f"Mean Difference:   {diff_in_means(hc_log_tau, sz_log_tau):.4f}")
print(f"Permutation p-val: {perm_res.pvalue:.4f}")

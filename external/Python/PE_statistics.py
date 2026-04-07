# %% 1. LIBRARIES
import pandas as pd
import numpy as np
import statsmodels.formula.api as smf
import statsmodels.api as sm
import matplotlib.pyplot as plt
import seaborn as sns
import scipy.stats as stats
# Set path (Adjust to your exact path)
PROJECT_FOLDER = '/Users/kaankeskin/projects/sch_pe/'
# 1. LOAD DATA
pe_raw = pd.read_csv(PROJECT_FOLDER + 'data/processed/wide_trial_pe_raw.csv')
subj_table = pd.read_csv(PROJECT_FOLDER + 'data/raw/subjects_list.csv')
# Clean column names of hidden spaces (crucial step from your data!)
subj_table.columns = subj_table.columns.str.strip()
# 2. FILTERING
exclude_ids = [9, 44, 77]
pe_raw = pe_raw[~pe_raw['denekId'].isin(exclude_ids)]
subj_table = subj_table[~subj_table['task-id'].isin(exclude_ids)]

# %% 3. RESHAPE TO LONG FORMAT
# First, identify the columns you actually want to melt (the trials)
trial_cols = [col for col in pe_raw.columns if col.startswith('trial_')]
# Now, melt the dataframe
long_pe = pd.melt(
    pe_raw, 
    id_vars=['denekId', 'group'],  # <--- Put columns you want to KEEP here
    value_vars=trial_cols,         # <--- Put columns you want to MELT here
    var_name='Trial', 
    value_name='PE'
)
# Now the Trial column is perfectly clean, and this will run without crashing!
long_pe['Trial_Num'] = long_pe['Trial'].str.replace('trial_', '').astype(int)
# Define Phase/Task (1: Trials 1-20, 2: 21-40, 3: 41-60)
long_pe['Task'] = pd.cut(long_pe['Trial_Num'], 
                         bins=[0, 20, 40, 60], 
                         labels=['1', '2', '3'])
# 5. MERGE WITH CLINICAL DATA
final_df = pd.merge(long_pe, subj_table, left_on="denekId", right_on="task-id", how="inner")
# Rename columns
final_df = final_df.rename(columns={
    'group_x': 'Group'
})
# Safe numeric conversion for Age (in case of spaces)
final_df['age'] = pd.to_numeric(final_df['age'].astype(str).str.strip(), errors='coerce')
# Mutate: Type conversions, Scaling, and Absolute PE
final_df['Group'] = final_df['Group'].astype('category')
final_df['sex'] = final_df['sex'].astype('category')
final_df['Task'] = final_df['Task'].astype('category')
final_df['Age_scaled'] = (final_df['age'] - final_df['age'].mean()) / final_df['age'].std()
final_df['absPE'] = final_df['PE'].abs()

# %% 6. RUN THE MIXED-EFFECTS MODEL
# 1. Pre-process data
# Drop NA or infinite values
final_df_clean = final_df.replace([np.inf, -np.inf], np.nan).dropna(subset=['absPE', 'Group', 'denekId', 'Age_scaled', 'sex', 'Task', 'PE'])
print("Running Linear Mixed-Effects Model...")
# 2. Run the model
# In statsmodels, 'groups' defines the random intercept (1 | denekId)
# C() explicitly tells statsmodels to treat the variable as categorical
formula = "absPE ~ C(Group) * C(Task) + C(sex) + Age_scaled"
res_model = smf.mixedlm(formula, final_df_clean, groups=final_df_clean["denekId"]).fit()
print(res_model.summary())

# %% VISUALIZATION FOR REFEREE 2
# Show the distribution of magnitude to confirm bimodality is resolved
plt.figure(figsize=(10, 6))
# FacetGrid is the seaborn equivalent of facet_wrap
g = sns.FacetGrid(final_df_clean, col="Task", hue="Group", palette="Set1", height=5, aspect=1)
g.map(sns.kdeplot, "absPE", fill=True, alpha=0.5)
# Add titles and labels
g.set_axis_labels("Absolute PE (Surprise Amount)", "Density")
g.set_titles(col_template="Phase / Task: {col_name}")
g.add_legend(title="Group (0=HC, 1=SZ)")
g.fig.suptitle("Magnitude of Prediction Error (|PE|) by Group and Phase", y=1.05)
plt.show()


# %% MODEL DIAGNOSTICS (Python Equivalents for DHARMa)
plt.style.use('./paper_theme.mplstyle')
# Get fitted values and residuals from the model
fitted_vals = res_model.fittedvalues
residuals = res_model.resid
fig, axes = plt.subplots(1, 2, figsize=(14, 6))
# 1. Q-Q Plot (Checks for Normality of Residuals)
# Equivalent to the left plot in DHARMa
sm.qqplot(residuals, line='45', fit=True, ax=axes[0])
axes[0].set_title("Q-Q Plot of Residuals")
# 2. Residuals vs Predicted (Checks for Dispersion / Heteroscedasticity)
# Equivalent to the right plot in DHARMa
axes[1].scatter(fitted_vals, residuals, alpha=0.5, color='blue')
axes[1].axhline(0, color='red', linestyle='--')
axes[1].set_xlabel("Fitted Values")
axes[1].set_ylabel("Residuals")
axes[1].set_title("Residuals vs. Fitted (Dispersion Check)")
plt.tight_layout()
plt.savefig("../../results/figures/qqplot.png")
plt.show()

# 3. Simple Outlier Check (Standardized Residuals > 3 or < -3)
std_res = (residuals - residuals.mean()) / residuals.std()
outliers = std_res[abs(std_res) > 3]
print(f"\nOutlier Diagnostics:")
print(f"Number of outlier data points (|Std Resid| > 3): {len(outliers)} out of {len(residuals)}")
print(f"Percentage of outliers: {(len(outliers) / len(residuals)) * 100:.2f}%")

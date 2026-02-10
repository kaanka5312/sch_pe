# %% LIBRARIES & DATA
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from model_functions import compute_log_likelihood, compute_null_log_likelihood_chance

# Yol tanımlaması
#PROJECT_FOLDER = '~/OneDrive/Belgeler/GitHub/sch_pe/' 
 PROJECT_FOLDER = '/Users/kaankeskin/projects/sch_pe/'

all_subjects = pd.read_csv(PROJECT_FOLDER + 'data/processed/all_subjects.csv')
subjects_params = pd.read_csv(PROJECT_FOLDER + 'data/processed/model_parameters.csv')

# %% BATCH CALCULATION
r2_results = []

print(f"{'ID':<8} | {'RL NLL':<10} | {'Null NLL':<10} | {'Pseudo R2':<10}")
print("-" * 50)

for idx in subjects_params['denekId'].unique():
    # 1. Parametreleri Çek
    subj_p = subjects_params[subjects_params['denekId'] == idx]
    alpha_val = subj_p['alpha'].item()
    tau_val = subj_p['tau'].item()

    # 2. Denek Verisini Hazırla
    subj_data = all_subjects[all_subjects['denekId'] == idx]
    choices_clean = subj_data['yatirim'].to_numpy()
    kazanc_clean = subj_data['kazanc'].to_numpy()

    # 3. NLL Hesaplamaları (Senin scriptindeki gibi)
    # rl_nll hesaplanırken compute_log_likelihood'un içindeki v_init ve v_safe'in 2.0 olduğundan emin ol
    rl_nll = compute_log_likelihood([alpha_val, tau_val], choices_clean, kazanc_clean)
    null_nll = compute_null_log_likelihood_chance(choices_clean)

    # 4. Senin Formülünle R2 Hesapla
    # McFadden's R2 = 1 - ((-rl_nll) / (-null_nll)) 
    # Not: Negatiflerin birbirini götürmesiyle 1 - (rl_nll / null_nll) ile aynıdır
    pseudo_r2 = 1 - ((-rl_nll) / (-null_nll))

    # 5. Sonuçları listeye ekle
    r2_results.append({
        'denekId': idx,
        'alpha': alpha_val,
        'tau': tau_val,
        'rl_nll': rl_nll,
        'null_nll': null_nll,
        'pseudo_r2': pseudo_r2
    })

    print(f"{idx:<8} | {rl_nll:<10.2f} | {null_nll:<10.2f} | {pseudo_r2:<10.4f}")

# %% SAVE & EXPORT
r2_df = pd.DataFrame(r2_results)
r2_df.to_csv(PROJECT_FOLDER + 'data/processed/subjects_r2_results.csv', index=False)

print("-" * 50)
print(f"Bitti! Toplam {len(r2_df)} denek işlendi ve kaydedildi.")

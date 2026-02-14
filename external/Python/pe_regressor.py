# %% LIBRARIES
import pandas as pd
import numpy as np
import os
from scipy.stats import zscore
import matplotlib.pyplot as plt
import seaborn as sns

# %% PATHS & DATA LOADING
# Kendi bilgisayar yoluna göre düzenle
PROJECT_FOLDER = 'C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/'

# 1. Ham deneme verileri (Her trial için yatırım ve kazanç bilgisi)
all_subjects = pd.read_csv(PROJECT_FOLDER + 'data/processed/all_subjects.csv')

# 2. Kaydedilmiş optimizasyon sonuçları (Her denek için en iyi alpha ve tau)
# Bu dosyanın içinde 'denekId', 'alpha', 'tau', 'group' ve 'pseudo_r2' olduğunu varsayıyoruz.
res_df = pd.read_csv(PROJECT_FOLDER + 'data/processed/final_group_parameters.csv')

# %% TRIAL-BY-TRIAL PE & VALUE GENERATION
print("Kaydedilmiş parametreler üzerinden PE ve V (Değer) hesaplanıyor...")

trial_by_trial_results = []

# Sadece parametre dosyasında bulunan (ve R2 >= 0 kriterini geçen) denekleri işleme al
for idx in res_df['denekId'].unique():
    # Kaydedilmiş en iyi alpha'yı çek
    best_alpha = res_df.loc[res_df['denekId'] == idx, 'alpha'].values[0]
    
    # Deneğin orijinal deneme verilerini al
    subj_data = all_subjects[all_subjects['denekId'] == idx].sort_values('sayac').copy()
    choices = subj_data['yatirim'].to_numpy()
    outcomes = subj_data['kazanc'].to_numpy()
    
    # Başlangıç değerleri (Normalleştirilmiş: Keep = 1.0)
    v = 1.0 
    
    pes = []
    values = []
    
    for t in range(len(choices)):
        # Karar anındaki beklenti (V)
        values.append(v)
        
        # PE hesapla (Rewards: 0, 20, 60 -> Normalizasyon: 0, 2.0, 6.0)
        r_t = outcomes[t] / 10.0
        pe_t = r_t - v
        pes.append(pe_t)
        
        # Sadece yatırım yapıldıysa beklentiyi güncelle
        if choices[t] == 1:
            v = v + best_alpha * pe_t
        else:
            # Yatırım yoksa (Keep) V değişmez
            pass

    # Hesaplanan değerleri deneğin verisine ekle
    subj_data['PE_raw'] = pes
    subj_data['V_value'] = values
    
    # fMRI analizi için denek içi normalize edilmiş (z-score) PE
    if np.std(pes) > 0:
        subj_data['PE_normalized'] = zscore(pes)
    else:
        subj_data['PE_normalized'] = 0.0
        
    trial_by_trial_results.append(subj_data)

# Tüm denekleri birleştir
all_trials_pe_df = pd.concat(trial_by_trial_results)

# Grup bilgilerini tekrar ekle (Eğer all_trials_pe_df'de yoksa)
all_trials_pe_df = all_trials_pe_df.merge(res_df[['denekId', 'group']], on='denekId', how='left')

# %% EXPORT FOR fMRI
# 1. Toplu CSV dosyası
all_trials_pe_df.to_csv(PROJECT_FOLDER + 'data/processed/trial_by_trial_fmri_regressors.csv', index=False)


# %% GÖRSELLEŞTİRME: PE Dinamiği (İlk Denek Örneği)
sample_id = all_trials_pe_df['denekId'].iloc[0]
sample_data = all_trials_pe_df[all_trials_pe_df['denekId'] == sample_id]
plt.figure(figsize=(12, 5))
plt.plot(sample_data['sayac'], sample_data['PE_raw'], label='Raw Prediction Error', marker='o', color='red')
plt.plot(sample_data['sayac'], sample_data['V_value'], label='Expected Value (V)', linestyle='--', color='blue')
plt.title(f'Denek {sample_id} - Trial-by-Trial RL Dinamiği')
plt.xlabel('Deneme No (Trial)')
plt.ylabel('Değer / PE')
plt.legend()
plt.grid(True, alpha=0.3)
plt.show()

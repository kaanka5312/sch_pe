# Util functions 
import numpy as np
import os
import numpy as np
import pandas as pd

def normalize_to_fmri(data):
    """The [-1, 1] scaling: 2*(x - min)/(max - min) - 1"""
    d_min, d_max = np.min(data), np.max(data)
    if d_max == d_min: return np.zeros_like(data)
    return 2 * (data - d_min) / (d_max - d_min) - 1

def save_to_task_folder(subj_id, pe, val, root_path):
    """Saves txt files into the subject's functional directory."""
    path = os.path.join(root_path, f"sub-{subj_id}", "func")
    os.makedirs(path, exist_ok=True)
    np.savetxt(os.path.join(path, 'pe_signed.txt'), pe, fmt='%.6f')
    np.savetxt(os.path.join(path, 'expected_value.txt'), val, fmt='%.6f')


def normalize_within_subject(data):
    """Maps array to [-1, 1] range: 2*(x - min)/(max - min) - 1"""
    d_min, d_max = np.min(data), np.max(data)
    if d_max == d_min: return np.zeros_like(data)
    return 2 * (data - d_min) / (d_max - d_min) - 1

def format_as_wide_csv(all_data, filename):
    """
    Converts list of dicts to a CSV where each trial is a column.
    Expected dict: {'denekId': id, 'vector': [t1, t2, ...]}
    """
    rows = []
    for entry in all_data:
        row = {'denekId': entry['denekId']}
        for i, val in enumerate(entry['vector']):
            row[f'trial_{i+1}'] = val
        rows.append(row)
    
    pd.DataFrame(rows).to_csv(filename, index=False)

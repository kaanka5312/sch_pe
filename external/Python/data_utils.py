# Util functions 
import numpy as np
import os

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

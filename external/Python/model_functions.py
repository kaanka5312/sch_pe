# This script includes in functions 
import numpy as np
from scipy.optimize import minimize

def compute_log_likelihood(params, choices, rewards):
    """
    Implements the Sigmoid Softmax and Rescorla-Wagner update.
    Returns Negative Log-Likelihood for optimization.
    """
    alpha, tau = params
    v = 0.5       # Initial Expected Value (Neutral)
    v_safe = 10   # Value of the 'Not Invest' choice
    
    neg_ll = 0
    eps = 1e-10   # Stability constant
    
    for t in range(len(choices)):
        # 1. Softmax (Sigmoid) function from RL.pdf
        # P(Invest) = 1 / (1 + exp(-tau * (V_invest - V_safe)))
        prob_invest = 1 / (1 + np.exp(-tau * (v - v_safe)))
        
        # 2. Likelihood of the actual observed choice
        p_choice = prob_invest if choices[t] == 1 else (1 - prob_invest)
        neg_ll -= np.log(p_choice + eps)
        
        # 3. Learning Update (Prediction Error)
        delta = rewards[t] - v
        v = v + alpha * delta
        
    return neg_ll

def fit_subject_parameters(choices, rewards):
    """Fits Alpha and Tau using Maximum Likelihood Estimation."""
    # Bounds: Alpha [0, 1], Tau [0, 20]
    res = minimize(compute_log_likelihood, x0=[0.5, 1.0], 
                   args=(choices, rewards), 
                   bounds=[(0, 1), (0.001, 20)], method='L-BFGS-B')
    return res.x # returns [alpha, tau]

def generate_rl_signals(alpha, choices, rewards):
    """Generates trial-by-trial PE and Value signals using best-fit alpha."""
    v = 0.5
    pe_history = []
    v_history = []
    
    for t in range(len(choices)):
        v_history.append(v)     # Expected Value BEFORE outcome
        delta = rewards[t] - v  # Signed Prediction Error
        pe_history.append(delta)
        v = v + alpha * delta   # Update for next trial
        
    return np.array(pe_history), np.array(v_history)

import json
import os

import numpy as np
from sklearn.datasets import make_classification
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import cross_val_score

# Get Slurm array task ID
task_id = int(os.getenv("SLURM_ARRAY_TASK_ID", "0"))

# Parameter combinations
param_grid = [
    {"n_estimators": 100, "max_depth": 10},
    {"n_estimators": 200, "max_depth": 15},
    {"n_estimators": 300, "max_depth": 20},
    {"n_estimators": 400, "max_depth": 25},
]

# Select parameters for this task
params = param_grid[task_id]

# Generate dataset
X, y = make_classification(n_samples=10000, n_features=20)

# Train and evaluate
clf = RandomForestClassifier(**params, random_state=42)
scores = cross_val_score(clf, X, y, cv=5)

# Save results
result = {
    "params": params,
    "mean_score": float(scores.mean()),
    "std_score": float(scores.std()),
    "node": os.uname().nodename,
}

with open(f"/shared/results/param_search_{task_id}.json", "w") as f:
    json.dump(result, f)

import os
import sys
import time
from pathlib import Path

import joblib
import numpy as np
from sklearn.datasets import make_classification
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

# Add project root to Python path
project_root = Path(__file__).parent.parent
sys.path.append(str(project_root))



def main():
    # Get Slurm job ID for output
    job_id = os.getenv("SLURM_JOB_ID", "no_id")

    # Create synthetic dataset
    X, y = make_classification(
        n_samples=10000, n_features=20, n_informative=15, n_redundant=5, random_state=42
    )
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

    # Train model
    start_time = time.time()
    clf = RandomForestClassifier(n_estimators=100, random_state=42)
    clf.fit(X_train, y_train)

    # Evaluate
    train_score = clf.score(X_train, y_train)
    test_score = clf.score(X_test, y_test)
    duration = time.time() - start_time

    # Ensure output directories exist
    for dir_path in ["/shared/results", "/shared/models", "/shared/logs"]:
        Path(dir_path).mkdir(parents=True, exist_ok=True)

    # Save results
    results_file = Path("/shared/results") / f"job_{job_id}_metrics.txt"
    with open(results_file, "w") as f:
        f.write(f"Training Score: {train_score:.4f}\n")
        f.write(f"Test Score: {test_score:.4f}\n")
        f.write(f"Training Duration: {duration:.2f} seconds\n")
        f.write(f"Running on node: {os.uname().nodename}\n")

    # Save model
    model_file = Path("/shared/models") / f"classifier_{job_id}.joblib"
    joblib.dump(clf, model_file)


if __name__ == "__main__":
    main()

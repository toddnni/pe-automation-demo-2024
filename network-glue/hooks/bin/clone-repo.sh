#!/usr/bin/env bash

# Exit on error
set -e
set -u

# Needs
# GIT_TOKEN
# REPO_URL
# REPO_DIR
# BRANCH_NAME

# Load the GitHub token from environment variable (e.g., from a Kubernetes secret)
if [ -z "$GIT_TOKEN" ]; then
  echo "Error: GIT_TOKEN is not set. Ensure it's passed as an environment variable."
  exit 1
fi

# Clone the repository using the GitHub token
echo "Cloning the repository..."
rm -rf "$REPO_DIR"
git clone https://"${GIT_TOKEN}":x-oauth-basic@"${REPO_URL#https://}" "$REPO_DIR"
cd "$REPO_DIR"

# Create a new branch for the changes
echo "Creating a new branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

echo "Repo cloned successfully!"

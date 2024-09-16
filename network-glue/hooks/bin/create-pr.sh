#!/usr/bin/env bash

# Exit on error
set -e
set -u

# Needs
# GIT_TOKEN
# REPO_URL
# REPO_DIR
# BRANCH_NAME
# FILE_TO_UPDATE
# Configuration
GIT_USER="shell-operator"
GIT_EMAIL="shell-operator@example.com"
COMMIT_MESSAGE="Update configuration file"
PR_TITLE="Proposal: Update Configuration $FILE_TO_UPDATE"
PR_BODY="This PR proposes updates to the configuration file."
TARGET_BRANCH="main"

# Load the GitHub token from environment variable (e.g., from a Kubernetes secret)
if [ -z "$GIT_TOKEN" ]; then
  echo "Error: GIT_TOKEN is not set. Ensure it's passed as an environment variable."
  exit 1
fi

# Add and commit the changes
cd "$REPO_DIR"
git add "$FILE_TO_UPDATE"
echo "Committing the changes with $GIT_USER <$GIT_EMAIL>..."
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git commit -m "$COMMIT_MESSAGE"

# Push the changes to the new branch
echo "Pushing the changes to the branch $BRANCH_NAME..."
git push origin "$BRANCH_NAME" -f

# example https://github.com/toddnni/pe-automation-demo-2024-repo
REPO_NAME="${REPO_URL##*/}"
REPO_OWNER="${REPO_URL#*.com/}"
REPO_OWNER="${REPO_OWNER%%/*}"
echo "Resolved repo owner and name: $REPO_OWNER, $REPO_NAME"


echo "Creating a pull request..."
curl -L -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GIT_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  --fail \
  -d "{ \"title\": \"${PR_TITLE}\", \"body\": \"${PR_BODY}\", \"head\": \"${BRANCH_NAME}\", \"base\": \"${TARGET_BRANCH}\" }" \
  "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls"


echo "Pull request created successfully!"

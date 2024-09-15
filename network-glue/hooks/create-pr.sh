#!/bin/bash

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
COMMIT_MESSAGE="Update configuration file"
PR_TITLE="Proposal: Update Configuration $FILE_TO_UPDATE"
PR_BODY="This PR proposes updates to the configuration file."
TARGET_BRANCH="master"

# Load the GitHub token from environment variable (e.g., from a Kubernetes secret)
if [ -z "$GIT_TOKEN" ]; then
  echo "Error: GIT_TOKEN is not set. Ensure it's passed as an environment variable."
  exit 1
fi

# Add and commit the changes
git add "$FILE_TO_UPDATE"
echo "Committing the changes..."
git commit -m "$COMMIT_MESSAGE"

# Push the changes to the new branch
echo "Pushing the changes to the branch $BRANCH_NAME..."
git push origin "$BRANCH_NAME"

echo "Creating a pull request..."
curl -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  -d @- \
  "${GITHUB_API_URL}/repos/${REPO_OWNER}/${REPO_NAME}/pulls" <<EOF
{
  "title": "${PR_TITLE}",
  "body": "${PR_BODY}",
  "head": "${BRANCH_NAME}",
  "base": "${TARGET_BRANCH}"
}
EOF

echo "Pull request created successfully!"

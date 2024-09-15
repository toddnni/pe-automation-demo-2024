#!/usr/bin/env bash

set -u

if [[ $1 == "--config" ]] ; then
  cat <<EOF
{
  "configVersion":"v1",
  "kubernetes":[{
    "apiVersion": "example.com/v1",
    "kind": "NetworkGlue",
    "executeHookOnEvent":["Added","Modified","Deleted"]
  }]
}
EOF
else
  cd "$(dirname $0)"
  # TODO works only for the first object
  type=$(jq -r '.[0].type' "${BINDING_CONTEXT_PATH}")
  namespace=$(jq -r '.[0].object.metadata.namespace' "${BINDING_CONTEXT_PATH}")
  name=$(jq -r '.[0].object.metadata.name' "${BINDING_CONTEXT_PATH}")
  eventType=$(jq -r '.[0].watchEvent' "${BINDING_CONTEXT_PATH}")
  source=$(jq -r '.[0].object.spec.source.networkCIDR' "${BINDING_CONTEXT_PATH}")
  target=$(jq -r '.[0].object.spec.target.networkCIDR' "${BINDING_CONTEXT_PATH}")
  targetPort=$(jq -r '.[0].object.spec.target.port' "${BINDING_CONTEXT_PATH}")
  REPO_URL="$REPO_URL"
  REPO_PATH=/git
  BRANCH_NAME="feature/update-config-$(date +%Y%m%d-%H%M%S)"
  FILE_TO_UPDATE="/git/$namespace-$name.json"

  if [[ $type == "Synchronization" ]] ; then
    # handle existing objects
  fi

  if [[ $type == "Event" ]] && ([[ $eventType = "Added" ]] || [[ $eventType = "Updated" ]]) ; then
    echo "${name} object is added or modified"
    bash clone-repo.sh
    echo "{ \"source\": \"$source\", \"target\": \"$target\", \"targetPort\": $port }" > "$FILE_TO_UPDATE"
    bash create-pr.sh
  elif [[ $type == "Event" ]] && [[ $eventType = "Deleted" ]] ; then
    echo "${name} object is deleted"
    bash clone-repo.sh
    echo "{ \"source\": \"$source\", \"target\": \"$target\", \"targetPort\": $port }" > "$FILE_TO_UPDATE"
    bash create-pr.sh
  fi
fi

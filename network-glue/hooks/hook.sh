#!/usr/bin/env bash

set -u

if [[ $# -gt 0 ]] && [[ $1 == "--config" ]] ; then
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
  cd "$(dirname $0)"
  # TODO works only for the first object
  type=$(jq -r '.[0].type' "${BINDING_CONTEXT_PATH}")
  namespace=$(jq -r '.[0].object.metadata.namespace' "${BINDING_CONTEXT_PATH}")
  name=$(jq -r '.[0].object.metadata.name' "${BINDING_CONTEXT_PATH}")
  version=$(jq -r '.[0].object.metadata.resourceVersion' "${BINDING_CONTEXT_PATH}")
  eventType=$(jq -r '.[0].watchEvent' "${BINDING_CONTEXT_PATH}")
  source=$(jq -r '.[0].object.spec.source.networkCIDR' "${BINDING_CONTEXT_PATH}")
  target=$(jq -r '.[0].object.spec.target.networkCIDR' "${BINDING_CONTEXT_PATH}")
  targetPort=$(jq -r '.[0].object.spec.target.port' "${BINDING_CONTEXT_PATH}")

  export REPO_URL="$(echo $REPO_URL | tr -d '\n ')" # strip newlines
  export REPO_DIR=/git
  export BRANCH_NAME="feature/update-config-$namespace-$name-$version"
  export FILE_TO_UPDATE="$REPO_DIR/$namespace-$name.json"

  if [[ $type == "Synchronization" ]] ; then
    # handle existing objects
    echo "sync asked"
  fi

  if [[ $type == "Event" ]] && ([[ $eventType = "Added" ]] || [[ $eventType = "Modified" ]]) ; then
    echo "${name} object is added or modified"
    bash bin/clone-repo.sh
    echo "{ \"source\": \"$source\", \"target\": \"$target\", \"targetPort\": \"$targetPort\" }" > "$FILE_TO_UPDATE"
    bash bin/create-pr.sh
  elif [[ $type == "Event" ]] && [[ $eventType = "Deleted" ]] ; then
    echo "${name} object is deleted"
    bash bin/clone-repo.sh
    rm "$FILE_TO_UPDATE"
    bash bin/create-pr.sh
  fi
fi

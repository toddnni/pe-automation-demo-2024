#!/usr/bin/env bash
set -e
set -u

if [ $# -ne 1 ]; then
  echo "usage: $0 name"
  exit 1
fi

APP="$1"
kubectl create ns "$APP"
kubectl create secret -n "$APP" generic db-secret --from-literal=PASSWORD="$(openssl rand -base64 12)"

cat > application-"$APP".values <<EOF
image:
  repository: ghcr.io/toddnni/toddnni/pe-automation-demo-2024
  tag: latest
azure:
  location: "$LOCATION"
  oidcIssuerUrl: "$AKS_OIDC_ISSUER"
  postgrePasswordSecret: "db-secret"
EOF

helm upgrade --install -n "$APP" --values application-"$APP".values "$APP" appstack-chart/

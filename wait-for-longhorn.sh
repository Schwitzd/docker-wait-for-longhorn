#!/bin/sh
set -e

START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "[INFO] Script started at: $START_TIME (UTC)"

# 1. Try Downward API env var
if [ -n "$POD_NAMESPACE" ]; then
  NS="$POD_NAMESPACE"
# 2. Fallback: check ServiceAccount file
elif [ -f /var/run/secrets/kubernetes.io/serviceaccount/namespace ]; then
  NS=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
else
  echo "[ERROR] POD_NAMESPACE env var not set and namespace file missing."
  exit 1
fi

echo "[INFO] POD_NAMESPACE: $NS"
echo "[INFO] Longhorn API: $LONGHORN_API"

while true; do
  NOT_READY=$(curl -s "${LONGHORN_API}/v1/volumes" \
    | jq -r --arg ns "$NS" '.data[] | select(.kubernetesStatus.namespace==$ns and .ready!=true) | .kubernetesStatus.pvcName')
  if [ -z "$NOT_READY" ]; then
    echo "[INFO] All Longhorn volumes in namespace $NS are ready."
    exit 0
  else
    echo "[WAIT] Not all volumes are ready. Waiting for: $NOT_READY"
    sleep 5
  fi
done

END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "[INFO] Script completed at: $END_TIME (UTC)"
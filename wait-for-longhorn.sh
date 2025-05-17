#!/bin/sh
set -e

NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
echo "[INFO] Namespace: $NAMESPACE"
echo "[INFO] Longhorn API: $LONGHORN_API"

while true; do
  NOT_READY=$(curl -s "${LONGHORN_API}/v1/volumes" \
    | jq -r --arg ns "$NAMESPACE" '.data[] | select(.kubernetesStatus.namespace==$ns and .ready!=true) | .kubernetesStatus.pvcName')
  if [ -z "$NOT_READY" ]; then
    echo "[INFO] All Longhorn volumes in namespace $NAMESPACE are ready."
    exit 0
  else
    echo "[WAIT] Not all volumes are ready. Waiting for: $NOT_READY"
    sleep 5
  fi
done
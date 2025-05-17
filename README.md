# docker-wait-for-longhorn

## Overview

`wait-for-longhorn` is a simple utility container designed for Kubernetes clusters using [Longhorn](https://longhorn.io/) for persistent storage—especially helpful on environments like Raspberry Pi clusters where Longhorn volumes may take significant time to become ready.

### Why?

On my RPi-based K3s cluster, I noticed that Longhorn volumes often take a long time to become ready after a reboot or deployment. However, Pods using Longhorn-backed PersistentVolumeClaims (PVCs) are often scheduled and started before the underlying volumes are actually ready and attached. This leads to repeated pod crashes, `CrashLoopBackOff` errors, and overall instability until Longhorn has finished its internal startup routines.

To work around this, I built this tiny image as an **init container**: it waits until all Longhorn volumes in the Pod’s namespace are ready before letting the main application container start. This ensures a much smoother startup experience—**even if some of the PVCs in the namespace are not directly used by the specific Pod**. It’s a simple, effective, and general solution for homelab and dev clusters.

## How It Works

When started, the script inside this container will:

1. **Detect the current Kubernetes namespace** using either:

   * The Downward API environment variable (`POD_NAMESPACE`) if available.
   * The file `/var/run/secrets/kubernetes.io/serviceaccount/namespace` as a fallback (this file is automatically mounted by Kubernetes in most cases).
2. **Query the Longhorn API** for all volumes in the current namespace.
3. **Wait until all PVCs in the namespace are marked as ready** in Longhorn before exiting successfully.

> **Note:** The script does *not* check which PVCs are attached to the current Pod. It simply waits for all Longhorn PVCs in the namespace. This is by design: it’s simpler and works reliably for typical microservices patterns, and avoids issues with missed volume dependencies.

## Namespace Detection: Two Ways

The script checks the current namespace in two ways, in this order:

### 1. Downward API Environment Variable

If you set the `POD_NAMESPACE` environment variable via the Downward API, the script will use this value:

```yaml
env:
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
```

Add this block under `env:` in your deployment, StatefulSet, or Job spec.

### 2. ServiceAccount Namespace File

If `POD_NAMESPACE` is not set, the script reads `/var/run/secrets/kubernetes.io/serviceaccount/namespace`, which contains the Pod’s namespace.

#### About `automountServiceAccountToken`

Kubernetes automatically mounts this file if `automountServiceAccountToken: true` (the default).
If you set `automountServiceAccountToken: false` in your Pod spec, **the file won’t be available**—improving security by not exposing ServiceAccount tokens or metadata inside the Pod.

* **Security tip:**
  If you don’t need the token or namespace file, set `automountServiceAccountToken: false` and use the Downward API env var instead.

## Example Usage

Add `docker-wait-for-longhorn` as an **init container** to your deployment or StatefulSet:

```yaml
initContainers:
  - name: wait-for-longhorn
    image: yourrepo/docker-wait-for-longhorn:latest
    env:
      - name: LONGHORN_API
        value: "http://longhorn-backend.longhorn-system.svc.cluster.local:9500"
      - name: POD_NAMESPACE
        valueFrom:
          fieldRef:
            fieldPath: metadata.namespace
```

The main application container will only start after all Longhorn PVCs in the namespace are ready.

## Notes

* **Scope:** The script waits for all PVCs in the namespace, not just those attached to the current Pod.
* **Longhorn API:** Make sure the `LONGHORN_API` endpoint is accessible from your Pod.
* **Platform:** Especially useful on slow or resource-constrained clusters (e.g., Raspberry Pi).

# 🧩 Kubernetes `kubectl` Admin Configuration Setup

This guide shows how to create and use a kubeconfig file for an **admin user** to securely access a high-availability Kubernetes cluster through the API server exposed behind a **load balancer**.

---

## 📦 Components

- **Cluster name**: `k8s-ha`
- **Load balancer hostname**: `lb` (resolves to IP via `/etc/hosts`)
- **Admin credentials**: `admin.crt`, `admin.key`
- **CA certificate**: `ca.crt`
- **API server endpoint**: `https://${LOADBALANCER}:6443`

---

## 🔧 Step-by-Step Configuration

### 1. 🧠 Get the Load Balancer IP

```bash
LOADBALANCER=$(getent hosts lb | awk '{ print $1 }')
```

This resolves the hostname `lb` to its corresponding IP address using `/etc/hosts`.

---

### 2. 🛠️ Set Cluster Parameters

```bash
kubectl config set-cluster k8s-ha \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${LOADBALANCER}:6443
```

- `--embed-certs=true`: embeds the CA cert directly in the kubeconfig
- The cluster is named `k8s-ha` and connects via the load balancer

---

### 3. 👤 Set Admin User Credentials

```bash
kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key
```

These point to the admin’s certificate and private key used for secure authentication.

---

### 4. 🔗 Set and Use the Context

```bash
kubectl config set-context k8s-ha \
    --cluster=k8s-ha \
    --user=admin

kubectl config use-context k8s-ha
```

- The context binds the cluster and user
- It's activated as the current working context

---

### 5. ✅ Verify Cluster Access

Check that the admin user can communicate with the API server and the cluster is healthy:

```bash
kubectl get componentstatuses
kubectl get nodes
```

You should see:
- All control plane components (`scheduler`, `controller-manager`, `etcd`) listed as `Healthy`
- All nodes listed as `NotReady`

---

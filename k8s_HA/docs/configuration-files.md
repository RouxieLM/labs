# 📘 Kubernetes Kubeconfig Bootstrapping Guide

## 🖥️ Context & Architecture

- **Control Plane Nodes**: `m1`, `m2`, `m3`  
- **Worker Nodes**: `w1`, `w2`, `w3`  
- **Load Balancer Hostname**: `lb`  
- **Cluster Name**: `k8s-ha`

---

## 🔧 Step 1: Set Load Balancer IP

```bash
LOADBALANCER=$(getent hosts lb | awk '{ print $1 }')
```

---

## ⚙️ Step 2: Generate `kube-proxy` Kubeconfig

```bash
kubectl config set-cluster k8s-ha \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://${LOADBALANCER}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
    --client-certificate=/var/lib/kubernetes/pki/kube-proxy.crt \
    --client-key=/var/lib/kubernetes/pki/kube-proxy.key \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
    --cluster=k8s-ha \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

**Results:**  
`kube-proxy.kubeconfig`

---

## ⚙️ Step 3: Generate `kube-controller-manager` Kubeconfig

```bash
kubectl config set-cluster k8s-ha \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=/var/lib/kubernetes/pki/kube-controller-manager.crt \
    --client-key=/var/lib/kubernetes/pki/kube-controller-manager.key \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
    --cluster=k8s-ha \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
```

**Results:**  
`kube-controller-manager.kubeconfig`

---

## ⚙️ Step 4: Generate `kube-scheduler` Kubeconfig

```bash
kubectl config set-cluster k8s-ha \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
    --client-certificate=/var/lib/kubernetes/pki/kube-scheduler.crt \
    --client-key=/var/lib/kubernetes/pki/kube-scheduler.key \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
    --cluster=k8s-ha \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
```

**Results:**  
`kube-scheduler.kubeconfig`

---

## ⚙️ Step 5: Generate `admin` Kubeconfig

```bash
kubectl config set-cluster k8s-ha \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

kubectl config set-context default \
    --cluster=k8s-ha \
    --user=admin \
    --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig
```

**Results:**  
`admin.kubeconfig`

---

## 📤 Step 6: Distribute Kubeconfig Files

### ▶️ To **Worker Nodes**:

```bash
for instance in w1 w2 w3; do
  scp kube-proxy.kubeconfig ${instance}:~/
done
```

### ▶️ To **Control Plane Nodes**:

```bash
for instance in m1 m2 m3; do
  scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done
```

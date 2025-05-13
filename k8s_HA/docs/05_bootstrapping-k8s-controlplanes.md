# 🧠 Kubernetes Control Plane Binary Installation & Service Configuration

This guide explains how to **manually install and configure Kubernetes control plane components** — `kube-apiserver`, `kube-controller-manager`, and `kube-scheduler` — using official binaries and systemd unit files.

---

## 📦 Components

- **Control Plane Nodes**: `master-1`, `master-2`, `master-3`
- **Load Balancer**: `lb`
- **Binaries Downloaded**:
  - `kube-apiserver`
  - `kube-controller-manager`
  - `kube-scheduler`
- **Service IP Range**: `10.96.0.0/16`
- **Pod CIDR**: `10.244.0.0/16`
- **Certificates and Kubeconfigs** stored in `/var/lib/kubernetes/`
- **Systemd unit files** created for all components

---

## 🧰 Step 1: Download Kubernetes Control Plane Binaries

```bash
KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
ARCH="amd64"

wget -q --show-progress --https-only --timestamping \
  "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-apiserver" \
  "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-controller-manager" \
  "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-scheduler"

chmod +x kube-apiserver kube-controller-manager kube-scheduler
sudo mv kube-apiserver kube-controller-manager kube-scheduler /usr/local/bin/
```

---

## 🔐 Step 2: Prepare Certificate Directory and Move Keys

```bash
sudo mkdir -p /var/lib/kubernetes/pki
sudo cp ca.crt ca.key /var/lib/kubernetes/pki

for c in kube-apiserver service-account apiserver-kubelet-client etcd-server kube-scheduler kube-controller-manager
do
  sudo mv "$c.crt" "$c.key" /var/lib/kubernetes/pki/
done

sudo chown root:root /var/lib/kubernetes/pki/*
sudo chmod 600 /var/lib/kubernetes/pki/*
```

---

## 🌐 Step 3: Set Networking Environment Variables

```bash
CONTROL01=$(getent hosts m1 | awk '{ print $1 }')
CONTROL02=$(getent hosts m2 | awk '{ print $1 }')
CONTROL03=$(getent hosts m3 | awk '{ print $1 }')
LOADBALANCER=$(getent hosts lb | awk '{ print $1 }')
PRIMARY_IP=$(hostname -I | grep -o '192\.168\.[0-9]\+\.[0-9]\+')

POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/16
```

---

## ⚙️ Step 4: Create and Enable systemd Unit for `kube-apiserver`

```bash
cat <<EOF > kube-apiserver.service
# ... [see original content above]
EOF

sudo mv kube-apiserver.service /etc/systemd/system/kube-apiserver.service
sudo chown root:root /etc/systemd/system/kube-apiserver.service
sudo chmod 644 /etc/systemd/system/kube-apiserver.service
```

---

## ⚙️ Step 5: Create and Enable systemd Unit for `kube-controller-manager`

```bash
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

cat <<EOF > kube-controller-manager.service
# ... [see original content above]
EOF

sudo mv kube-controller-manager.service /etc/systemd/system/kube-controller-manager.service
sudo chown root:root /etc/systemd/system/kube-controller-manager.service
sudo chmod 644 /etc/systemd/system/kube-controller-manager.service
```

---

## ⚙️ Step 6: Create and Enable systemd Unit for `kube-scheduler`

```bash
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/

cat <<EOF > kube-scheduler.service
# ... [see original content above]
EOF

sudo mv kube-scheduler.service /etc/systemd/system/kube-scheduler.service
sudo chown root:root /etc/systemd/system/kube-scheduler.service
sudo chmod 644 /etc/systemd/system/kube-scheduler.service
```

---

## 🔒 Step 7: Secure Kubeconfig Files

```bash
sudo chmod 600 /var/lib/kubernetes/*.kubeconfig
```

---

## 🚀 Step 8: Start All Control Plane Components

```bash
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

---

## 📊 Step 9: Verify Component Status

```bash
kubectl get componentstatuses --kubeconfig admin.kubeconfig
```

> This should show the health of scheduler, controller-manager, and etcd (as seen by kube-apiserver).

---

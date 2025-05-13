# 🧠 Kubernetes Control Plane Binary Installation & Service Configuration

This guide explains how to **manually install and configure Kubernetes control plane components** — `kube-apiserver`, `kube-controller-manager`, and `kube-scheduler` — using official binaries and systemd unit files.

You can use **tmux** or any multi-exec tool for multi-host orchestration, as these commands must be executed on each master node.

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
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${PRIMARY_IP} \\
  --allow-privileged=true \\
  --apiserver-count=2 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --enable-admission-plugins=NodeRestriction,ServiceAccount \\
  --enable-bootstrap-token-auth=true \\
  --etcd-cafile=/var/lib/kubernetes/pki/ca.crt \\
  --etcd-certfile=/var/lib/kubernetes/pki/etcd-server.crt \\
  --etcd-keyfile=/var/lib/kubernetes/pki/etcd-server.key \\
  --etcd-servers=https://${CONTROL01}:2379,https://${CONTROL02}:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/pki/ca.crt \\
  --kubelet-client-certificate=/var/lib/kubernetes/pki/apiserver-kubelet-client.crt \\
  --kubelet-client-key=/var/lib/kubernetes/pki/apiserver-kubelet-client.key \\
  --runtime-config=api/all=true \\
  --service-account-key-file=/var/lib/kubernetes/pki/service-account.crt \\
  --service-account-signing-key-file=/var/lib/kubernetes/pki/service-account.key \\
  --service-account-issuer=https://${LOADBALANCER}:6443 \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/pki/kube-apiserver.crt \\
  --tls-private-key-file=/var/lib/kubernetes/pki/kube-apiserver.key \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
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
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --allocate-node-cidrs=true \\
  --authentication-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --authorization-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --bind-address=127.0.0.1 \\
  --client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --cluster-cidr=${POD_CIDR} \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/pki/ca.crt \\
  --cluster-signing-key-file=/var/lib/kubernetes/pki/ca.key \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --node-cidr-mask-size=24 \\
  --requestheader-client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --root-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --service-account-private-key-file=/var/lib/kubernetes/pki/service-account.key \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
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
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig \\
  --leader-elect=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo mv kube-scheduler.service /etc/systemd/system/kube-scheduler.service
sudo chown root:root /etc/systemd/system/kube-scheduler.service
sudo chmod 644 /etc/systemd/system/kube-scheduler.service
```

---

## 🔒 Step 7: Secure Kubeconfig and encryption Files

```bash
sudo chown root:root /var/lib/kubernetes/encryption-config.yaml
sudo chown root:root /var/lib/kubernetes/*.kubeconfig
sudo chmod 600 /var/lib/kubernetes/*.kubeconfig
sudo chmod 600 /var/lib/kubernetes/encryption-config.yaml
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

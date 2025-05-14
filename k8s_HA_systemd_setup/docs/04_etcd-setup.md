# ⚙️ Manual etcd Installation & Configuration on Control Plane Nodes

This guide details how to manually install and configure an `etcd` cluster on Kubernetes control plane nodes (`m1`, `m2`, `m3`), including **TLS setup** and **systemd service**.

You can use **tmux** or any multi-exec tool for multi-host orchestration, as these commands must be executed on each **master** node.

---

## 📦 Step 1: Download and Install etcd

```bash
ETCD_VERSION="v3.5.21"
ARCH="amd64"  # or "arm64" depending on your system

wget -q --show-progress --https-only --timestamping \
  "https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz"

tar -xvf etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz
sudo mv etcd-${ETCD_VERSION}-linux-${ARCH}/etcd* /usr/local/bin/
```

---

## 🔐 Step 2: Prepare Directories & Copy Certificates

```bash
sudo mkdir -p /etc/etcd /var/lib/etcd /var/lib/kubernetes/pki

sudo cp etcd-server.key etcd-server.crt /etc/etcd/
sudo cp ca.crt /var/lib/kubernetes/pki/

sudo chown root:root /etc/etcd/*
sudo chmod 600 /etc/etcd/*

sudo chown root:root /var/lib/kubernetes/pki/*
sudo chmod 600 /var/lib/kubernetes/pki/*

# Symlink the CA certificate
sudo ln -s /var/lib/kubernetes/pki/ca.crt /etc/etcd/ca.crt
```

---

## 🌐 Step 3: Set Cluster Node IPs

```bash
CONTROL01=$(getent hosts m1 | awk '{ print $1 }')
CONTROL02=$(getent hosts m2 | awk '{ print $1 }')
CONTROL03=$(getent hosts m3 | awk '{ print $1 }')

ETCD_NAME=$(hostname -s)
PRIMARY_IP=$(hostname -I | grep -o '192\.168\.[0-9]\+\.[0-9]\+')
```

---

## 🧾 Step 4: Create the systemd Unit File

```bash
cat <<EOF > etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${PRIMARY_IP}:2380 \\
  --listen-peer-urls https://${PRIMARY_IP}:2380 \\
  --listen-client-urls https://${PRIMARY_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${PRIMARY_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster master-1=https://${CONTROL01}:2380,master-2=https://${CONTROL02}:2380,master-3=https://${CONTROL03}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo mv etcd.service /etc/systemd/system/etcd.service
sudo chown root:root /etc/systemd/system/etcd.service
sudo chmod 644 /etc/systemd/system/etcd.service
```

---

## 🚀 Step 5: Start etcd

```bash
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

---

## 🔎 Step 6: Verify etcd Cluster Membership

```bash
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key
```

---

## ✅ Result

You will have a secure, manually configured, TLS-encrypted etcd cluster, running as a systemd service on all your control plane nodes.
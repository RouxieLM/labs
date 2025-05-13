# ⚙️ Manual etcd Installation & Configuration on Control Plane Nodes

This guide details how to manually install and configure an `etcd` cluster on Kubernetes control plane nodes (`m1`, `m2`, `m3`), including **TLS setup**, **systemd service**, and **tmux usage** for multi-host orchestration.

---

## 🪟 Use `tmux` for Multi-Node Setup (Optional)

`tmux` lets you manage multiple terminal sessions in a single window, ideal for setting up `etcd` on multiple nodes simultaneously.

### 📌 Install tmux

```bash
sudo apt install tmux
```

### 📋 Common `tmux` commands

| Action                    | Command                        |
|---------------------------|--------------------------------|
| Start new session         | `tmux new -s etcd-setup`       |
| Split window (horizontal) | `Ctrl-b "`                     |
| Split window (vertical)   | `Ctrl-b %`                     |
| Move between panes        | `Ctrl-b + arrow key`           |
| Sync input to all panes   | `Ctrl-b :setw synchronize-panes on` |
| Disable sync              | `Ctrl-b :setw synchronize-panes off` |
| Detach session            | `Ctrl-b d`                     |
| Reattach later            | `tmux attach -t etcd-setup`    |

### 🧪 Example use case:

1. `tmux new -s etcd-setup`
2. Split into 3 vertical panes: SSH into `m1`, `m2`, `m3`
3. Enable input sync across panes
4. Paste installation and configuration steps — they run on all nodes at once

---

## 📦 Step 1: Download and Install etcd

```bash
ETCD_VERSION="v3.5.9"
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
PRIMARY_IP=$(getent hosts $(hostname -s) | awk '{ print $1 }')
```

---

## 🧾 Step 4: Create the systemd Unit File

```bash
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name \${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://\${PRIMARY_IP}:2380 \\
  --listen-peer-urls https://\${PRIMARY_IP}:2380 \\
  --listen-client-urls https://\${PRIMARY_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://\${PRIMARY_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controlplane01=https://\${CONTROL01}:2380,controlplane02=https://\${CONTROL02}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
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

## 🪟 Optional: Use `tmux` for Parallel Setup Across Nodes

### 📌 Why use `tmux`?
- Run the same setup in parallel across multiple control plane nodes.
- Keep sessions open if your SSH disconnects.

### 🧰 Basic `tmux` commands

| Action | Command |
|--------|---------|
| Start new session | `tmux new -s etcd-setup` |
| Split window (horizontal) | `Ctrl-b "` |
| Split window (vertical) | `Ctrl-b %` |
| Move between panes | `Ctrl-b + arrow key` |
| Synchronize input to all panes | `Ctrl-b :setw synchronize-panes on` |
| Exit sync mode | `Ctrl-b :setw synchronize-panes off` |
| Detach | `Ctrl-b d` |
| Reattach | `tmux attach -t etcd-setup` |

```bash
# Example usage:
tmux new -s etcd-setup
# Split into 3 vertical panes (one per node)
# SSH into m1, m2, m3 in each pane
# Enable synchronize-panes and paste setup steps once
```

---

## ✅ Result

You will have a secure, manually configured, TLS-encrypted etcd cluster, running as a systemd service on all your control plane nodes.
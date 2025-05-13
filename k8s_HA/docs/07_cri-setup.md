# ⚙️ Kubernetes Worker Node Setup: System Prep, Container Runtime, and Kube Tools

This guide walks through configuring each Kubernetes **control plane node** with necessary kernel modules, sysctl settings, containerd runtime, and the Kubernetes package repository.

You can use **tmux** or any multi-exec tool for multi-host orchestration, as these commands must be executed on each **worker** node.

---

## 📦 Components

- **Target nodes**: All worker nodes (`w1`, `w2`, `w3`)
- **OS**: Debian/Ubuntu-based systems
- **Container runtime**: `containerd`
- **Kubernetes tools**: `kubectl`, `kubernetes-cni`, etc.
- **Kernel modules**: `overlay`, `br_netfilter`
- **CNI dependencies**: `ipvsadm`, `ipset`

---

## 🔧 Step 1: Install Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

---

## 🧱 Step 2: Enable Required Kernel Modules

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

---

## 🛠️ Step 3: Configure Required Sysctl Parameters

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

These settings are required to allow Kubernetes networking to work correctly.

---

## 🌐 Step 4: Add Kubernetes APT Repository

```bash
KUBE_LATEST=$(curl -L -s https://dl.k8s.io/release/stable.txt | awk 'BEGIN { FS="." } { printf "%s.%s", $1, $2 }')

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
```

---

## 📦 Step 5: Install Container Runtime and Kube Tools

```bash
sudo apt-get install -y containerd kubernetes-cni kubectl ipvsadm ipset
```

---

## ⚙️ Step 6: Configure containerd

```bash
sudo mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd
```

This enables **`SystemdCgroup = true`**, which is required for proper integration with Kubernetes control plane components.

---
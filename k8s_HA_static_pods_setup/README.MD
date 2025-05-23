# 🚀 Setup a Kubernetes HA Cluster with Static Pods (Locally via Vagrant & VirtualBox)

This project sets up a **High Availability (HA) Kubernetes Cluster** on your local machine using **Vagrant** and **VirtualBox**, deploying control plane components as **static pods**.

It provisions 7 VMs: 3 master nodes, 3 worker nodes, and 1 load balancer.

---

## 🛠️ Requirements

- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Vagrant](https://www.vagrantup.com/downloads)
- (Optional) PowerShell (for `start_vm.ps1` on Windows)

---

## 📁 Project Structure

```
.
├── Vagrantfile           # Defines and provisions all VMs
├── nodes.rb              # Describes each VM: name, CPU, memory, IP
├── provision.sh          # Provision script run on each VM
└── start_vm.ps1          # PowerShell script to launch VMs (Windows only)
```

---

## 🚀 Quick Start (Linux/macOS)

```bash
# Clone the repository
git clone https://your.repo.url.git
cd k8s_HA_static_pods_setup

# Start all VMs (master-1 starts first for SSH key propagation)
vagrant up
```

---

## 🚀 Quick Start (Windows)

Open PowerShell as Administrator and run:

```powershell
.\start_vm.ps1
```

> This ensures `master-1` is started first, followed by the other nodes in parallel.

---

## 🖥️ VM Inventory

| Name         | Role          | IP Address     | Host Alias        | CPUs | RAM    |
|--------------|---------------|----------------|-------------------|------|--------|
| master-1     | Control Plane | 192.168.56.11  | m1, master-1      | 4    | 2048MB |
| master-2     | Control Plane | 192.168.56.12  | m2, master-2      | 4    | 2048MB |
| master-3     | Control Plane | 192.168.56.13  | m3, master-3      | 4    | 2048MB |
| worker-1     | Node          | 192.168.56.21  | w1, worker-1      | 4    | 3072MB |
| worker-2     | Node          | 192.168.56.22  | w2, worker-2      | 4    | 3072MB |
| worker-3     | Node          | 192.168.56.23  | w3, worker-3      | 4    | 3072MB |
| loadbalancer | HAProxy       | 192.168.56.30  | lb, loadbalancer  | 4    | 512MB  |

> All nodes are accessible locally by their short alias names (e.g., `m1`, `w2`, `lb`), thanks to `/etc/hosts` entries.

---

## 🔧 What’s Automated

- OS updates and essential tools installation (`curl`, `vim`, etc.)
- `kubectl` installation and alias setup (except on load balancer)
- Autocompletion for `kubectl` (`k` alias)
- SSH key generation on `master-1` and distribution to all nodes
- `/etc/hosts` entries for cluster node resolution

---

## ⚙️ Control Plane Deployment Method

This setup uses **static pods** (via manifest files in `/etc/kubernetes/manifests/`) to deploy:

- `kube-apiserver`
- `kube-controller-manager`
- `kube-scheduler`

These components are managed directly by the kubelet on each control plane node.

> If you're looking for the **systemd-based** setup instead, check the [`k8s_HA_systemd_setup`](../k8s_HA_systemd_setup/) folder.

---

## 🧹 Cleanup

```bash
# Destroy all VMs
vagrant destroy -f

# Re-run provisioning
vagrant provision
```

---

## 🧠 Notes

- VMs use static IPs in the `192.168.56.X` range (private network).
- Kubernetes is **not** installed by default. Use this as a base for manual or scripted Kubernetes deployment using static pod manifests.
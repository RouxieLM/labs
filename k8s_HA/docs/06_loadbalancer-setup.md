# ⚖️ Kubernetes HA Load Balancing with HAProxy

This guide shows how to install and configure **HAProxy** as a TCP load balancer to distribute API server traffic across multiple Kubernetes control plane nodes. This setup enables high availability of the Kubernetes API layer.

---

## 📦 Components

- **Load Balancer Host**: `lb`
- **Control Plane Nodes**: `m1`, `m2`, `m3`
- **HAProxy**: Installed from `apt`
- **API Port**: `6443`
- **Health Check**: Enabled for control plane nodes using `tcp-check`

---

## 🧰 Step 1: Install HAProxy

```bash
sudo apt-get update && sudo apt-get install -y haproxy
```

- Installs HAProxy on the `lb` node, which will be used to distribute Kubernetes API traffic.

---

## 🌐 Step 2: Set Control Plane IPs

```bash
CONTROL01=$(getent hosts m1 | awk '{ print $1 }')
CONTROL02=$(getent hosts m2 | awk '{ print $1 }')
CONTROL03=$(getent hosts m3 | awk '{ print $1 }')
LOADBALANCER=$(getent hosts lb | awk '{ print $1 }')
```

- These variables resolve hostnames to IP addresses using `/etc/hosts` or DNS.

---

## ⚙️ Step 3: Configure HAProxy

```bash
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
frontend kubernetes
    bind ${LOADBALANCER}:6443
    option tcplog
    mode tcp
    default_backend kubernetes-controlplane-nodes

backend kubernetes-controlplane-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server controlplane01 ${CONTROL01}:6443 check fall 3 rise 2
    server controlplane02 ${CONTROL02}:6443 check fall 3 rise 2
    server controlplane03 ${CONTROL03}:6443 check fall 3 rise 2
EOF
```

- **Frontend**: Listens on port `6443` of the load balancer IP
- **Backend**: Forwards requests to all control plane nodes using **round-robin**
- **Health checks**: Ensure that traffic is sent only to healthy nodes

> 🔧 **Note:** Fixed a typo — the third server was also named `controlplane02`; changed to `controlplane03`.

---

## 🔄 Step 4: Restart HAProxy

```bash
sudo systemctl restart haproxy
```

- Applies the new configuration

---

## ✅ Step 5: Test the Load Balancer

```bash
curl -k https://${LOADBALANCER}:6443/version
```

- Verifies that the HAProxy load balancer is correctly proxying to one of the Kubernetes API servers
- The `-k` flag skips TLS verification for this test

---

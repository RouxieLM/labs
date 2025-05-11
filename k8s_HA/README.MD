# 🚀 Setup Kubernetes High Availability (HA) Cluster with Vagrant & VirtualBox

This guide helps you provision a **multi-master Kubernetes cluster** (HA setup) locally using **Vagrant** and **VirtualBox**, with manual TLS certificate generation and secure node communication.

---

## 📦 Components

- **3 Control Plane Nodes**: `m1`, `m2`, `m3`
- **3 Worker Nodes**: `w1`, `w2`, `w3`
- **1 Load Balancer**: `lb`
- **TLS Certificates**: Created with `openssl`
- **Service CIDR**: `10.96.0.0/24`

---

## 🔧 Step 1: Set Host IPs & Service IP

Use `getent` to resolve IPs from `/etc/hosts`:

```bash
CONTROL01=$(getent hosts m1 | awk '{ print $1 }')
CONTROL02=$(getent hosts m2 | awk '{ print $1 }')
CONTROL03=$(getent hosts m3 | awk '{ print $1 }')
LOADBALANCER=$(getent hosts lb | awk '{ print $1 }')

SERVICE_CIDR=10.96.0.0/24
API_SERVICE=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.1", $1, $2, $3) }')

# Print values
echo "CONTROL01: $CONTROL01"
echo "CONTROL02: $CONTROL02"
echo "CONTROL03: $CONTROL03"
echo "LOADBALANCER: $LOADBALANCER"
echo "API_SERVICE: $API_SERVICE"
```

---

## 🔐 Step 2: Create `openssl.cnf` for Kubernetes API Server Cert

```bash
cat > openssl.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = ${API_SERVICE}
IP.2 = ${CONTROL01}
IP.3 = ${CONTROL02}
IP.4 = ${CONTROL03}
IP.5 = ${LOADBALANCER}
IP.6 = 127.0.0.1
EOF
```

This configuration ensures your API server certificate is valid for all possible endpoints used by nodes and clients.

---

## 📤 Step 3: Distribute Certificates to Nodes

### ▶️ Copy to **Control Plane Nodes**:

```bash
for instance in m1 m2 m3; do
  scp -o StrictHostKeyChecking=no \
    ca.crt ca.key kube-apiserver.key kube-apiserver.crt \
    apiserver-kubelet-client.crt apiserver-kubelet-client.key \
    service-account.key service-account.crt \
    etcd-server.key etcd-server.crt \
    kube-controller-manager.key kube-controller-manager.crt \
    kube-scheduler.key kube-scheduler.crt \
    ${instance}:~/
done
```

### ▶️ Copy to **Worker Nodes**:

```bash
for instance in w1 w2 w3; do
  scp ca.crt kube-proxy.crt kube-proxy.key ${instance}:~/
done
```

---

## 📘 Notes

- Ensure `~/.ssh/known_hosts` does not block your `scp` with unknown hosts — hence the use of `-o StrictHostKeyChecking=no`.
- The file `openssl.cnf` is crucial for correct SAN values on the API server cert. Missing or incorrect SANs will cause TLS failures in your cluster.
- This is part of a manual Kubernetes installation ("Kubernetes the Hard Way"-style).

---

## 📚 References

- [Kubernetes the Hard Way (by Kelsey Hightower)](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [cfssl (optional tool for cert management)](https://github.com/cloudflare/cfssl)
- [OpenSSL Docs](https://www.openssl.org/docs/)

---

## ✅ Next Steps

- Install Kubernetes components (`kubeadm`, `kubelet`, `kubectl`) on each node
- Manually initialize the cluster and join control/worker nodes
- Configure kubeconfigs and RBAC

Happy hacking! 🔧☸️

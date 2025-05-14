# 🐆 Install Calico Network Plugin

---

## 1. 📥 Apply the Calico Manifest

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.0/manifests/calico.yaml
```

This command installs the Calico CNI plugin, which provides container networking and network policy capabilities for the cluster.

---

## 2. 📊 Check Pod Status in kube-system Namespace

```bash
kubectl get pods -n kube-system
```

Verify that the Calico components (`calico-node`, `calico-kube-controllers`) and other system pods are up and running.

---

## 3. 🌐 Confirm Node Readiness

```bash
kubectl get nodes
```

Once Calico is running, all nodes should report a `Ready` status instead of `NotReady`.

---

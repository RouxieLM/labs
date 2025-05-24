# 🧠 Deploy and Test CoreDNS + Headless Service Resolution

---

## 1. 📝 Create CoreDNS Configuration File

Open a new file:

```bash
vi coredns.yaml
```

Paste the contents of `deployment/coredns.yaml` (available in the repo) manifest into the editor, then save and exit.

---

## 2. 🚀 Apply CoreDNS Deployment

```bash
kubectl apply -f coredns.yaml
```

This deploys CoreDNS into the `kube-system` namespace.

---

## 3. 📊 Verify CoreDNS Pod Status

```bash
kubectl get pods -l k8s-app=kube-dns -n kube-system
```

You should see two `coredns` pods in the `Running` state.

---

## 4. 🧪 Deploy Busybox for DNS Testing

```bash
kubectl run busybox -n default --image=busybox:1.28 --restart Never --command -- sleep 180
```

This creates a temporary test pod that can be used to perform DNS queries.

---

## 5. 🔍 Confirm Busybox Is Running

```bash
kubectl get pods -n default -l run=busybox
```

Ensure the `busybox` pod is in `Running` status.

---

## 6. 🧾 Test DNS Resolution of Kubernetes Internal Services

```bash
kubectl exec -ti -n default busybox -- nslookup kubernetes
```

Expected result:
- DNS server: `10.96.0.10`
- Name: `kubernetes.default.svc.cluster.local`

---

## 7. 📦 Launch a Second Busybox Pod

```bash
kubectl run busybox2 -n default --image=busybox:1.28 --restart Never --command -- sleep 180
```

This second pod will be exposed via a headless service.

---

## 8. 🌐 Create Headless Service for Pod DNS Discovery

```bash
kubectl expose pod busybox2 --name=busybox2 --port=80 --target-port=80 --cluster-ip=None
```

This creates a **headless service** that allows direct DNS resolution of the pod.

---

## 9. ✅ Test DNS Resolution of Headless Service

```bash
kubectl exec -ti busybox -- nslookup busybox2
```

Expected result:
- DNS server responds with the pod IP of `busybox2`

---

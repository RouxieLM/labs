# 🔐 Kubernetes Secrets Encryption at Rest Configuration

This guide explains how to generate and deploy an **encryption configuration** to enable **Secrets encryption at rest** in a Kubernetes cluster.

---

## 📦 Context & Components

- **Control Plane Nodes**: `m1`, `m2`, `m3`
- **Encryption Method**: `aescbc` (AES-256 CBC mode)
- **Target Resource**: Kubernetes `secrets`
- **Storage Location**: `/var/lib/kubernetes/encryption-config.yaml` on control planes

---

## 🔧 Step 1: Generate a 256-bit (32 byte) Encryption Key

```bash
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

**Purpose:**
- Securely generates a 256-bit key and encodes it in base64 (required by Kubernetes).
- This key will be used by the control plane to encrypt/decrypt secrets on disk.

---

## 📄 Step 2: Create the Encryption Configuration File

```bash
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
```

**Purpose:**
- Creates a file that tells the kube-apiserver how to encrypt Kubernetes `secrets`.
- Uses the `aescbc` provider with the generated key as primary.
- Includes `identity` as a fallback for unencrypted values (read-only, no encryption).

**Structure:**
- `resources`: What to encrypt (only `secrets` in this case)
- `providers`: Ordered list of encryption methods; first one is used for new writes

---

## 🚚 Step 3: Distribute the Encryption Configuration to All Control Plane Nodes

```bash
for instance in m1 m2 m3; do
  scp encryption-config.yaml ${instance}:~/
done
```

**Purpose:**
- Copies the generated `encryption-config.yaml` to the home directory of each control plane node (`m1`, `m2`, `m3`).
- All control planes must use the **same encryption key** to decrypt previously stored data.

---

## 📁 Step 4: Move the Config File into the Correct Location on Each Control Plane Node

```bash
for instance in m1 m2 m3; do
  ssh ${instance} sudo mkdir -p /var/lib/kubernetes/
  ssh ${instance} sudo mv encryption-config.yaml /var/lib/kubernetes/
done
```

**Purpose:**
- Ensures the kube-apiserver can load the encryption config at startup.
- The file must be moved to `/var/lib/kubernetes/encryption-config.yaml` to match the expected path configured via the `--encryption-provider-config` flag in the kube-apiserver manifest.

---

## ✅ What Happens Next?

Once the encryption config is in place and kube-apiserver is restarted with this flag:

```yaml
--encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml
```

Kubernetes will:
- Start encrypting all **new `Secret` objects** stored in etcd.
- **Old secrets will remain unencrypted** until a manual re-encryption process is done (`kubectl get secrets -o yaml | kubectl replace -f -`).

---

## 🛡️ Summary

| Step | Purpose |
|------|---------|
| Generate encryption key | Secure random 256-bit AES key |
| Create encryption config | Instructs kube-apiserver how to encrypt secrets |
| Copy to control planes | Ensures all kube-apiservers use the same config |
| Move to correct path | Required for kube-apiserver to pick it up on boot |

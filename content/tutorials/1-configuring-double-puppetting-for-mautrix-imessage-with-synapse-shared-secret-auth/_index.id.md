---
title: "Mengaktifkan Double-Puppeting mautrix-imessage dengan Synapse Shared Secret Auth"
description: "Panduan mengkonfigurasi double-puppeting untuk mautrix-imessage pada Synapse modern menggunakan modul Shared Secret Authenticator untuk kompatibilitas legacy."
date: 2025-06-16T08:00:00+07:00
lastmod: 2025-06-16T08:00:00+07:00
draft: false
noindex: false
featured: true
pinned: false
comments: true
categories:
  - homelab
  - matrix
tags:
  - matrix
  - synapse
  - mautrix-imessage
  - imessage
  - bridge
  - kubernetes
  - docker
authors:
  - kareemlukitomo
---

Panduan ini menjelaskan cara mengkonfigurasi double-puppeting untuk `mautrix-imessage` menggunakan metode `login_shared_secret` di Synapse. Cara ini memungkinkan bridge untuk mengautentikasi sebagai pengguna dengan cara yang kompatibel dengan instalasi Synapse modern. https://github.com/devture/matrix-synapse-shared-secret-auth

Diuji dengan:

* [mautrix-imessage](https://mau.dev/mautrix/imessage) v0.1.0+dev.c3534649
* Synapse v1.131.0

## Prasyarat

Atur value `login_shared_secret` yang sudah ditentukan di file konfigurasi bridge `mautrix-imessage`

```yaml
    # Jika diatur, double puppeting akan diaktifkan otomatis tanpa perlu pengguna mencari access token dan menjalankan `login-matrix` manual.
    login_shared_secret: "password_rahasia_dan_panjang_di_sini"
```

> 🔒 Secret value ini juga akan digunakan di konfigurasi Synapse. Pastikan valuenya sama.

## Untuk Docker Compose

### Langkah 1: Unduh Modul Auth

Unduh `shared_secret_authenticator.py` ke direktori lokal, misal `./synapse/custom_modules/`

```bash
mkdir -p ./synapse/custom_modules
curl -o ./synapse/custom_modules/shared_secret_authenticator.py \
  https://raw.githubusercontent.com/devture/matrix-synapse-shared-secret-auth/master/shared_secret_authenticator.py
```

### Langkah 2: Mount Modul ke Container Synapse

Edit service Synapse di `docker-compose.yml`:

```yaml
services:
  synapse:
    volumes:
      - ./synapse/data:/data
      - ./synapse/custom_modules/shared_secret_authenticator.py:/usr/local/lib/python3.12/site-packages/shared_secret_authenticator.py
```

> 🔁 Sesuaikan path dengan versi Python di image Anda.

### Langkah 3: Update Konfigurasi Synapse

Edit `homeserver.yaml`:

```yaml
modules:
  - module: shared_secret_authenticator.SharedSecretAuthProvider
    config:
      shared_secret: "password_rahasia_dan_panjang_di_sini"
      m_login_password_support_enabled: true
```

### Langkah 4: Restart Container Synapse dan Bridge

```bash
docker compose restart synapse
docker compose restart mautrix-imessage
```

### Langkah 5: Konfirmasi Berhasil

Cek log Synapse dan bridge untuk konfirmasi double-puppeting:

```text
INF Successfully automatically enabled custom puppet module=User/@kareem:lukitomo.com
```

## Untuk Kubernetes

### Langkah 1: Unduh Modul Auth

```bash
curl -O https://raw.githubusercontent.com/devture/matrix-synapse-shared-secret-auth/master/shared_secret_authenticator.py
```

### Langkah 2: Buat ConfigMap untuk Modul

```bash
kubectl create configmap synapse-module-shared-secret \
  --from-file=shared_secret_authenticator.py \
  -n matrix
```

### Langkah 3: Update Konfigurasi Synapse

Edit `homeserver.yaml` Anda:

```yaml
modules:
  - module: shared_secret_authenticator.SharedSecretAuthProvider
    config:
      shared_secret: "password_rahasia_dan_panjang_di_sini"
      m_login_password_support_enabled: true
```

### Langkah 4: Mount Modul ke Pod Synapse

Tambahkan volume:

```yaml
volumes:
  - name: shared-secret-auth-module
    configMap:
      name: synapse-module-shared-secret
```

Mount volume ke container:

```yaml
volumeMounts:
  - name: shared-secret-auth-module
    mountPath: /usr/local/lib/python3.12/site-packages/shared_secret_authenticator.py
    subPath: shared_secret_authenticator.py
```

> 🔁 Sesuaikan path Python jika perlu.

### Langkah 5: Restart Deployment

```bash
kubectl rollout restart deployment/synapse -n matrix
kubectl rollout restart deployment/mautrix-imessage -n matrix
```

### Langkah 6: Konfirmasi Berhasil

```text
INF Successfully automatically enabled custom puppet module=User/@kareem:lukitomo.com
```

---

✅ Selesai! `mautrix-imessage` kini sepenuhnya berfungsi dengan double-puppeting via Synapse Shared Secret Auth di lingkungan Kubernetes maupun Docker.

---
title: "Enable mautrix-imessage Double-Puppeting with Synapse Shared Secret Auth"
description: "A guide to configure double-puppeting for mautrix-imessage on modern Synapse versions using the Shared Secret Authenticator module for legacy compatibility."
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

This guide explains how to configure double-puppeting for `mautrix-imessage` using the `login_shared_secret` method in Synapse. This approach allows the bridge to authenticate as users in a way compatible with modern Synapse installations. https://github.com/devture/matrix-synapse-shared-secret-auth

Tested with:

* [mautrix-imessage](https://mau.dev/mautrix/imessage) v0.1.0+dev.c3534649
* Synapse v1.131.0

## Pre-requisites

Configure a pre-defined `login_shared_secret` value in the config file of `mautrix-imessage` bridge

```yaml
    # If set, double puppeting will be enabled automatically instead of the user
    # having to find an access token and run `login-matrix` manually.
    login_shared_secret: "a_very_secret_and_long_password_here"
```

> 🔒 This secret will also be used in your Synapse configuration. Make sure they match.


## For Docker Compose

### Step 1: Download the Auth Module

Download `shared_secret_authenticator.py` into a local directory, e.g. `./synapse/custom_modules/`

```bash
mkdir -p ./synapse/custom_modules
curl -o ./synapse/custom_modules/shared_secret_authenticator.py \
  https://raw.githubusercontent.com/devture/matrix-synapse-shared-secret-auth/master/shared_secret_authenticator.py
```

### Step 2: Mount the Module into the Synapse Container

Edit your `docker-compose.yml` Synapse service:

```yaml
services:
  synapse:
    volumes:
      - ./synapse/data:/data
      - ./synapse/custom_modules/shared_secret_authenticator.py:/usr/local/lib/python3.12/site-packages/shared_secret_authenticator.py
```

> 🔁 Again, adjust the path based on the actual Python version in your image.

### Step 3: Update Synapse Configuration

Edit `homeserver.yaml`:

```yaml
modules:
  - module: shared_secret_authenticator.SharedSecretAuthProvider
    config:
      shared_secret: "a_very_secret_and_long_password_here"
      m_login_password_support_enabled: true
```

### Step 4: Restart Synapse and Bridge Containers

```bash
docker compose restart synapse
# if mautrix-imessage is containerized too:
docker compose restart mautrix-imessage
```

### Step 5: Confirm Success

Check Synapse and bridge logs for double-puppeting confirmation:

```text
INF Successfully automatically enabled custom puppet module=User/@kareem:lukitomo.com
```
## For Kubernetes

### Step 1: Download the Auth Module

```bash
curl -O https://raw.githubusercontent.com/devture/matrix-synapse-shared-secret-auth/master/shared_secret_authenticator.py
```

### Step 2: Create a ConfigMap for the Module

```bash
kubectl create configmap synapse-module-shared-secret \
  --from-file=shared_secret_authenticator.py \
  -n matrix
```

### Step 3: Update Synapse Configuration

Edit your `homeserver.yaml`:

```yaml
modules:
  - module: shared_secret_authenticator.SharedSecretAuthProvider
    config:
      shared_secret: "a_very_secret_and_long_password_here"
      m_login_password_support_enabled: true
```

### Step 4: Mount the Module into Synapse Pod

Add the volume:

```yaml
volumes:
  - name: shared-secret-auth-module
    configMap:
      name: synapse-module-shared-secret
```

Mount the volume in the container:

```yaml
volumeMounts:
  - name: shared-secret-auth-module
    mountPath: /usr/local/lib/python3.12/site-packages/shared_secret_authenticator.py
    subPath: shared_secret_authenticator.py
```

> 🔁 Adjust the Python version path as needed.

### Step 5: Restart Deployments

```bash
kubectl rollout restart deployment/synapse -n matrix
kubectl rollout restart deployment/mautrix-imessage -n matrix
```

### Step 6: Confirm Success

```text
INF Successfully automatically enabled custom puppet module=User/@kareem:lukitomo.com
```

---

✅ You're done! `mautrix-imessage` is now fully functional with double-puppeting via Synapse Shared Secret Auth in both Kubernetes and Docker environments.

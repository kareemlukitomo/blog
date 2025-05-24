---
title: "Secure Atuin with ZFS Encrypted Zvol"
description: "Relocate Atuin’s history DB to an encrypted ZFS volume for performance and encryption."
date: 2025-05-24T17:00:00+07:00
lastmod: 2025-05-24T17:00:00+07:00
draft: false
noindex: false
featured: false
pinned: false
comments: true
categories:
  - devops
  - homelab
tags:
  - zfs
  - encryption
  - atuin
  - linux
  - debian
authors:
  - kareemlukitomo
---

This guide documents how to relocate [Atuin](https://atuin.sh)’s shell history database to a ZFS-encrypted volume (`zvol`) for better performance and encryption. It enables automatic unlock and mount on boot. Tested on Debian with ZFS root (`rpool`), suitable for reproducible homelab setups. This setup helps me alleviate the [performance issue when using atuin with ZFS filesystem](https://github.com/atuinsh/atuin/issues/952) 

---

## 1. Destroy previous Atuin and zvol state (start clean)

Before removing atuin, we can also optionally do `atuin store push`to make sure the local history is pushed/synced to the remote server

```bash
pkill atuin
rm -rf ~/.local/share/atuin

sudo umount /home/kareem/.local/share/atuin 2>/dev/null || true
sudo zfs destroy rpool/data/atuin 2>/dev/null || true
```

---

## 2. Generate persistent encryption key

```bash
sudo mkdir -p /etc/zfs/keys
sudo dd if=/dev/urandom bs=1 count=32 of=/etc/zfs/keys/atuin.key
sudo chmod 600 /etc/zfs/keys/atuin.key
```

---

## 3. Create encrypted zvol

```bash
sudo zfs create -V 1G \
  -o encryption=on \
  -o keyformat=raw \
  -o keylocation=file:///etc/zfs/keys/atuin.key \
  rpool/data/atuin
```

---

## 4. Format and mount zvol manually

```bash
sudo mkfs.ext4 /dev/zvol/rpool/data/atuin
sudo mount /dev/zvol/rpool/data/atuin ~/.local/share/atuin
```

---

## 5. Create systemd key loader service

```ini
# /etc/systemd/system/zfs-load-key@rpool-data-atuin.service
[Unit]
Description=Load key for ZFS dataset %I
DefaultDependencies=no
Before=home-kareem-.local-share-atuin.mount

[Service]
Type=oneshot
ExecStart=/usr/sbin/zfs load-key %I

[Install]
WantedBy=home-kareem-.local-share-atuin.mount
```

Enable the service:

```bash
sudo systemctl enable zfs-load-key@rpool-data-atuin.service
```

---

## 6. Create systemd mount unit

```ini
# /etc/systemd/system/home-kareem-.local-share-atuin.mount
[Unit]
Description=Encrypted Atuin ZVOL mount
After=zfs-load-key@rpool-data-atuin.service
Requires=zfs-load-key@rpool-data-atuin.service

[Mount]
What=/dev/zvol/rpool/data/atuin
Where=/home/kareem/.local/share/atuin
Type=ext4
Options=defaults

[Install]
WantedBy=multi-user.target
```

Enable the mount:

```bash
sudo systemctl enable home-kareem-.local-share-atuin.mount
```

---

## 7. **Reboot before using Atuin**

**Important**: Reboot now to ensure the zvol is unlocked and mounted by systemd.

This ensures your `atuin login` config and DB are stored in the encrypted mount.

---

## 8. Login and import history

```bash
atuin login
atuin import auto
atuin store pull
atuin stats
```

---

## ✅ Done!

Your shell history is now encrypted at rest using ZFS native encryption and mounted automatically on boot.

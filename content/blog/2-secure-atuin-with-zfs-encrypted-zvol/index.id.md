---
title: "Amankan Atuin dengan ZFS Encrypted Zvol"
description: "Pindahkan database riwayat Atuin ke volume ZFS terenkripsi untuk performa dan enkripsi lebih baik."
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

Panduan ini mendokumentasikan cara memindahkan database riwayat shell [Atuin](https://atuin.sh) ke volume ZFS terenkripsi (`zvol`) demi performa dan enkripsi yang lebih baik. Proses ini memungkinkan unlock dan mount otomatis saat boot. Diuji pada Debian dengan root ZFS (`rpool`), cocok untuk setup homelab yang _reproducible_. Setup ini membantu saya mengatasi [masalah performa saat menggunakan atuin dengan filesystem ZFS](https://github.com/atuinsh/atuin/issues/952).

---

## 1. Hapus Atuin dan zvol sebelumnya (mulai dari awal)

Sebelum menghapus atuin, kita juga bisa melakukan `atuin store push` secara opsional untuk memastikan riwayat lokal sudah dikirim/disinkronkan ke server remote.

```bash
pkill atuin
rm -rf ~/.local/share/atuin

sudo umount /home/kareem/.local/share/atuin 2>/dev/null || true
sudo zfs destroy rpool/data/atuin 2>/dev/null || true
```

---

## 2. Buat kunci enkripsi persisten

```bash
sudo mkdir -p /etc/zfs/keys
sudo dd if=/dev/urandom bs=1 count=32 of=/etc/zfs/keys/atuin.key
sudo chmod 600 /etc/zfs/keys/atuin.key
```

---

## 3. Buat zvol terenkripsi

```bash
sudo zfs create -V 1G \
  -o encryption=on \
  -o keyformat=raw \
  -o keylocation=file:///etc/zfs/keys/atuin.key \
  rpool/data/atuin
```

---

## 4. Format dan mount zvol secara manual

```bash
sudo mkfs.ext4 /dev/zvol/rpool/data/atuin
sudo mount /dev/zvol/rpool/data/atuin ~/.local/share/atuin
```

---

## 5. Buat service systemd untuk memuat kunci

```ini
# /etc/systemd/system/zfs-load-key@rpool-data-atuin.service
[Unit]
Description=Load key untuk ZFS dataset %I
DefaultDependencies=no
Before=home-kareem-.local-share-atuin.mount

[Service]
Type=oneshot
ExecStart=/usr/sbin/zfs load-key %I

[Install]
WantedBy=home-kareem-.local-share-atuin.mount
```

Aktifkan service:

```bash
sudo systemctl enable zfs-load-key@rpool-data-atuin.service
```

---

## 6. Buat unit mount systemd

```ini
# /etc/systemd/system/home-kareem-.local-share-atuin.mount
[Unit]
Description=Mount Atuin ZVOL terenkripsi
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

Aktifkan mount:

```bash
sudo systemctl enable home-kareem-.local-share-atuin.mount
```

---

## 7. **Reboot sebelum menggunakan Atuin**

**Penting**: Lakukan reboot sekarang untuk memastikan zvol sudah di-unlock dan di-mount oleh systemd.

Ini memastikan konfigurasi `atuin login` dan DB tersimpan di mount terenkripsi.

---

## 8. Login dan impor riwayat

```bash
atuin login
atuin import auto
atuin store pull
atuin stats
```

---

## ✅ Selesai!

Riwayat shell Anda sekarang terenkripsi saat tidak digunakan menggunakan enkripsi native ZFS dan otomatis di-mount saat boot.

# pi NAS — Drive Setup & Wipe Tutorial

A guide for setting up and wiping drives on a Raspberry Pi NAS following the [timoknapp/pi-nas](https://github.com/timoknapp/pi-nas) repo.

---

## Prerequisites

Before touching any drives, stop all running Docker containers to avoid data corruption or locked mounts:

```bash
cd ~/pi-nas
docker-compose down

# Full clean slate (removes volumes too)
docker-compose down -v
```

Check nothing is still accessing your mount points:

```bash
lsof | grep /mnt/Idrive
```

Kill any PIDs that show up before proceeding.

---

## Identify Your Drives

```bash
lsblk
# or
sudo fdisk -l
```

**Key things to note:**
- `mmcblk0` — your SD card (Pi OS). **Do not touch this.**
- `zram0` — existing swap via compressed RAM. Fast, leave it.
- `sda`, `sdb`, etc. — your external drives to work with.

---

## Wipe a Drive

> ⚠️ This is destructive. Double-check your drive letter before running anything.

If the drive is currently mounted, unmount it first:

```bash
sudo umount /mnt/Idrive
```

Then reload systemd if prompted:

```bash
sudo systemctl daemon-reload
```

### Check Partition Table Type

MBR partition tables are capped at 2TB. For drives **larger than 2TB**, use `gdisk` (GPT). For smaller drives, `fdisk` works fine.

---

## Partition the Drive

### Drives > 2TB — Use `gdisk` (GPT)

```bash
sudo gdisk /dev/sda
```

Inside gdisk:
1. Press `o` → `y` — create a fresh GPT partition table
2. Press `n` → `1` → default first sector → `-8G` — main storage (leaves 8GB for swap)
3. Press Enter to accept hex code `8300` (Linux filesystem)
4. Press `n` → `2` → default → default — swap partition
5. Type `8200` for hex code (Linux swap)
6. Press `p` to review layout
7. Press `w` → `y` to write and exit

### Drives ≤ 2TB — Use `fdisk` (MBR)

```bash
sudo fdisk /dev/sda
```

Inside fdisk:
1. Press `d` repeatedly to delete all existing partitions
2. Press `n` → accept defaults — main storage partition (size e.g. `+3500G`)
3. Press `n` → accept defaults for remaining space — swap partition
4. Press `t` → select swap partition → type `82` (Linux swap)
5. Press `p` to review
6. Press `w` to write and exit

---

## Format the Partitions

```bash
# Main storage — format as ext4 and add a label
sudo mkfs.ext4 /dev/sda1
sudo e2label /dev/sda1 Idrive

# Swap partition
sudo mkswap /dev/sda2
sudo swapon /dev/sda2
```

Verify swap is active:

```bash
swapon --show
free -h
```

---

## Mount the Main Drive

```bash
# Change owner of /mnt directory
sudo chown root:users /mnt

# Create mount point
sudo mkdir -p /mnt/Idrive

# Mount by label
sudo mount /dev/disk/by-label/Idrive /mnt/Idrive/

# Set permissions
sudo chown -R max:users /mnt/Idrive/
chmod -R 775 /mnt/Idrive/
```

---

## Auto-Mount on Boot (fstab)

```bash
sudo nano /etc/fstab
```

Add these lines:

```
LABEL=Idrive  /mnt/Idrive  ext4  defaults  0  0
/dev/sda2     none         swap  sw        0  0
```

Test without rebooting:

```bash
sudo mount -a
sudo systemctl daemon-reload
```

Verify with:

```bash
lsblk
df -h
```

---

## Swap Size Reference

For a Raspberry Pi 4 (4GB RAM):

| Partition | Recommended Size |
|---|---|
| Main storage | Everything minus swap |
| Swap | 8GB |

> Note: `zram0` already provides fast in-memory swap. The disk swap partition is a slower safety net for when RAM is under heavy load.

---

## Recommended Directory Structure on Drive

```
/mnt/Idrive/
├── appdata/
│   ├── heimdall/
│   ├── pihole/
│   ├── jellyfin/
│   ├── pyload/
│   ├── homebridge/
│   └── monitoring/
├── media/
│   ├── movies/
│   └── tv/
├── downloads/
├── nas/
└── timemachine/
```

---

## Environment Variables & Secrets

Keep passwords out of `docker-compose.yml` by using a `.env` file:

```bash
nano ~/pi-nas/.env
```

```env
# User
USER_ID=1000
GROUP_ID=1000
TZ=America/Phoenix

# Paths
PATH_TO_DISK=/mnt/Idrive
PATH_TO_DATA=/mnt/Idrive

# Passwords
PIHOLE_PASSWORD=yourpassword
CLOUDFLARE_TUNNEL_TOKEN=yourtoken
POSTGRES_PASSWORD=yourpassword
```

Add to `.gitignore` so it's never committed:

```bash
echo ".env" >> ~/pi-nas/.gitignore
```

Verify all variables resolve before starting containers:

```bash
docker-compose config
```

---

## Start Containers

```bash
cd ~/pi-nas
docker-compose up -d
```

Check everything is running:

```bash
docker ps
```

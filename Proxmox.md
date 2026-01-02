# Proxmox

## General

- Backup
- Mount disks
  - To Proxmox VM
  - Pass USB through to LXC Containers

## LXC / VMs

All LXC installation scripts can be found [here](https://tteck.github.io/Proxmox/).

### NAS Debian 12 (VM)

#### Backup Files to OneDrive

Automated encrypted incremental backup to OneDrive using rclone with crypt (encrypts filenames + content).

##### Prerequisites

```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash
```

##### Configure rclone for OneDrive

###### Step 1: Create OneDrive Remote

```bash
rclone config
```

1. Press `n` for new remote
2. Name: `onedrive`
3. Storage: Select `Microsoft OneDrive`
4. Leave `client_id` and `client_secret` blank (press Enter)
5. Edit advanced config: `n`
6. Use auto config: `n` (since NAS has no browser)
7. Copy the provided URL and open it on a computer with a browser
8. Log in to your Microsoft account and authorize rclone
9. Paste the token back into the terminal
10. Choose account type: `onedrive` (personal) or `business`
11. Select drive: `4` (OneDrive personal)
12. Confirm and quit config

Verify it works:
```bash
rclone lsd onedrive:
```

###### Step 2: Create Encrypted (Crypt) Remote

```bash
rclone config
```

1. Press `n` for new remote
2. Name: `onedrive-crypt`
3. Storage: Select `Encrypt/Decrypt a remote` (crypt)
4. Remote to encrypt: `onedrive:Backup` (folder on OneDrive where encrypted files go)
5. Filename encryption: `standard` (recommended)
6. Directory name encryption: `true` (recommended)
7. Enter a strong password (save this - you need it to decrypt!)
8. Optionally add a salt password for extra security
9. Confirm and quit config

Verify encryption works:
```bash
# Test write
echo "test" | rclone rcat onedrive-crypt:test.txt

# Verify it's encrypted on OneDrive
rclone lsl onedrive:Backup  # Should show encrypted filename

# Verify you can read it back
rclone cat onedrive-crypt:test.txt  # Should show "test"

# Cleanup test file
rclone deletefile onedrive-crypt:test.txt
```

##### Setup Backup Script

```bash
# Copy script to NAS
scp scripts/backup-to-onedrive.sh user@NAS_IP:/home/<user>/bin/

# Or create directly on NAS
sudo mkdir -p /home/<user>/bin
sudo nano /home/<user>/bin/backup-to-onedrive.sh
```

Edit the configuration variables in the script:
```bash
SOURCE_DIR="/path/to/folder/to/backup"       # Folder to backup
RCLONE_CRYPT_REMOTE="onedrive-crypt"         # Must match rclone crypt remote name
```

Make executable and test:
```bash
chmod +x /home/<user>/bin/backup-to-onedrive.sh
/home/<user>/bin/backup-to-onedrive.sh
```

##### Setup Cronjob

```bash
crontab -e
```

Add one of these schedules:
```bash
# Daily at 2 AM
0 2 * * * /home/<user>/bin/backup-to-onedrive.sh >> /var/log/backup-onedrive.log 2>&1

# Weekly on Sunday at 3 AM
0 3 * * 0 /home/<user>/bin/backup-to-onedrive.sh >> /var/log/backup-onedrive.log 2>&1
```

##### Verify Backups

```bash
# List backups (decrypted view)
rclone ls onedrive-crypt:/

# List raw encrypted files on OneDrive
rclone ls onedrive:Backup/

# Check logs
tail -f /var/log/backup-onedrive.log
```

##### Restore from Backup

```bash
# Preview what would be restored (dry run)
rclone sync onedrive-crypt:/ /path/to/restore/ --dry-run

# Restore entire backup
rclone sync onedrive-crypt:/ /path/to/restore/folder --progress

# Restore specific file
rclone copy onedrive-crypt:path/to/file.txt /local/destination/ --progress

# Restore specific folder
rclone copy onedrive-crypt:subfolder/ /local/destination/ --progress
```

##### Backup rclone Config (Important!)

The `rclone.conf` file contains your encryption password. Without it, backups are **unrecoverable**.

```bash
# Backup config to a safe location
cp ~/.config/rclone/rclone.conf /safe/backup/location/

# Or export and save the config
rclone config show > rclone-config-backup.txt
```

Store the config backup in a separate location (e.g., password manager, different cloud, USB drive).


### Cloudflard (LXC)

### Nginx Proxy Manager (LXC)

#### SSL Certificates

- `*.local.$DOMAIN.com, local.$DOMAIN.com``
- DNS Challenge
- Configure the DNS where your Domain is hosted to have a CNAME record with Proxy Status "DNS only".
    - CNAME: local.$DOMAIN.com | DNS Only
- Setup DNS to point to local IP of Nginx Proxy Manager (local.$DOMAIN.com > IP_OF_NPM)

#### Proxy Hosts

- Nginx Proxy Manager
    - local.$DOMAIN.com > http://IP_OF_NPM:81
    - SSL Certificate: local.$DOMAIN.com, Force SSL, HTTP/2 Support
- Docker (Portainer)
    - docker.local.$DOMAIN.com > https://IP_OF_DOCKER:9443
    - SSL Certificate: local.$DOMAIN.com, Force SSL, HTTP/2 Support
- PVE
    - pve.local.$DOMAIN.com > https://IP_OF_PVE:8006, WebSocket Support enabled
    - SSL Certificate: local.$DOMAIN.com, Force SSL, HTTP/2 Support
- Heimdall Dashboard
    - dash.local.$DOMAIN.com > http://IP_OF_HEIMDALL:7990
    - SSL Certificate: local.$DOMAIN.com, Force SSL, HTTP/2 Support
- PiHole
    - pihole.local.$DOMAIN.com > http://IP_OF_PIHOLE:80
    - SSL Certificate: local.$DOMAIN.com, Force SSL, HTTP/2 Support
- Home Assistant
    - haos.local.$DOMAIN.com > http://IP_OF_HOMEASSISTANT:8123, WebSocket Support enabled
    - SSL Certificate: local.$DOMAIN.com, Force SSL, HTTP/2 Support
    - Advanced:
        ```
        proxy_set_header Host $host;
        proxy_pass_header Authorization; 
        proxy_set_header Upgrade $http_upgrade; 
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Forwarded-For $remote_addr;
        ```

#### Proxmox post work

- Import TLS certificates genereted by Nginx Proxy Manager
- Export Nginx Proxy Manager certificates: "SSL Certificates" > "Select three dots for local.$DOMAIN.com" > "Download".
- Import certificates to Proxmox: "PVE" > "System" > "Certificates" > "Upload Custom Certificate (Private Key and Chain)" > "Upload".

### PiHole (LXC)

### Heimdall (LXC)

### Home Assistant (VM)

- Change Configuration to allow Proxy usage of Nginx Proxy Manager
- `configuration.yaml` >
    ```
    http:
      use_x_forwarded_for: true
      trusted_proxies:
        - 192.168.178.0/24
    ```
- [link](https://community.home-assistant.io/t/home-assistant-400-bad-request-docker-proxy-solution/322163)

### Jdownloader / pyLoad (LXC)

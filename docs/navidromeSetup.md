# Navidrome Setup

## Docker Compose

Add the following service to your `docker-compose.yml`:

```yaml
navidrome:
  image: deluan/navidrome:latest
  container_name: navidrome
  user: ${USER_ID}:${GROUP_ID}
  environment:
    - TZ=${TZ}
    - ND_MUSICFOLDER=/music
    - ND_DATAFOLDER=/data
    - ND_LOGLEVEL=info
    - ND_SESSIONTIMEOUT=24h
    - ND_ENABLETRANSCODINGCONFIG=true
    - ND_DEFAULTTHEME=Dark
  volumes:
    - ${PATH_TO_DISK}/appdata/navidrome:/data
    - ${PATH_TO_DISK}/media/music:/music:ro
  ports:
    - 4533:4533
  restart: unless-stopped
```

## Permissions Fix

If Navidrome fails to start with a `permission denied` error on `/data/cache`, fix ownership of the drive:

```bash
sudo chown -R max:users /mnt/Idrive/
chmod -R 775 /mnt/Idrive/
```

Then restart the container:

```bash
docker compose restart navidrome
```

## Accessing Navidrome

| Method | URL |
|---|---|
| Local network | `http://<pi-ip>:4533` |
| Tailscale (remote) | `http://<tailscale-ip>:4533` |

On first visit, you'll be prompted to create an admin account.

## Mobile Apps (Subsonic-compatible)

| Platform | App | Notes |
|---|---|---|
| Android | Symfonium | Paid, best overall |
| Android | Ultrasonic | Free |
| iOS | play:Sub | Supports CarPlay |
| iOS | Substreamer | Free |

When setting up a mobile app, enter:
- **Server URL:** `http://<tailscale-ip>:4533`
- **Username/Password:** your admin credentials

## Notes

- Navidrome auto-scans your music folder on startup. Monitor progress with `docker logs navidrome`.
- Since `PATH_TO_DISK` and `PATH_TO_DATA` point to the same location, music should live at `${PATH_TO_DISK}/media/music`.
- Jellyfin and Navidrome can share the same music directory without duplication.

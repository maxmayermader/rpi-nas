# Homepage Dashboard Setup — deathstar

## Docker Compose Service

```yaml
homepage:
  image: ghcr.io/gethomepage/homepage:latest
  container_name: homepage
  ports:
    - 80:3000
  volumes:
    - ${PATH_TO_DISK}/appdata/homepage:/app/config
    - /var/run/docker.sock:/var/run/docker.sock:ro
  environment:
    - PUID=${USER_ID}
    - PGID=${GROUP_ID}
    - TZ=${TZ}
    - HOMEPAGE_ALLOWED_HOSTS=deathstar,deathstar:80,${LOCAL_TAIL_HOST},${LOCAL_TAIL_HOST}:80
  group_add:
    - "983"  # docker GID from: stat /var/run/docker.sock
  restart: unless-stopped
```

---

## Config File Locations

All config files live at:
```
${PATH_TO_DISK}/appdata/homepage/
├── services.yaml   # app links
├── widgets.yaml    # system stats, weather, speedtest
└── settings.yaml  # theme, layout
```

Homepage hot-reloads on save — no container restart needed.

---

## services.yaml

```yaml
- Media:
    - Jellyfin:
        href: http://YOUR_TAILSCALE_IP:8096
        description: Media Server
        icon: jellyfin.png
        container: jellyfin

    - Navidrome:
        href: http://YOUR_TAILSCALE_IP:4533
        description: Music Streaming
        icon: navidrome.png
        container: navidrome

- Photos & Files:
    - Immich:
        href: http://YOUR_TAILSCALE_IP:2283
        description: Photo Backup
        icon: immich.png
        container: immich_server

    - Nextcloud:
        href: http://YOUR_TAILSCALE_IP:8081
        description: File Storage
        icon: nextcloud.png
        container: nextcloud

- Monitoring & Network:
    - Grafana:
        href: http://YOUR_TAILSCALE_IP:3000
        description: Metrics Dashboard
        icon: grafana.png
        container: grafana

    - Pi-hole:
        href: http://YOUR_TAILSCALE_IP:8080/admin
        description: DNS & Ad Blocking
        icon: pi-hole.png
        widget:
          type: pihole
          url: http://pihole:80
          key: YOUR_PIHOLE_API_KEY
```

> **Pi-hole API key:** Run `docker exec pihole pihole -a -g` or get it from Pi-hole UI → Settings → API → Show API token.

---

## widgets.yaml

```yaml
- openweathermap:
    label: Phoenix, AZ
    latitude: 33.4484
    longitude: -112.0740
    units: imperial
    apiKey: YOUR_WEATHERAPI_KEY  # free at weatherapi.com

- resources:
    label: System
    cpu: true
    memory: true
    disk: /

- datetime:
    text_size: xl
    format:
      dateStyle: short
      timeStyle: short
```

> **Weather API key:** Sign up free at [weatherapi.com](https://www.weatherapi.com) and paste your key above.

> **Speedtest:** The `kjake/internet-speedtest-docker` container writes to InfluxDB only — it has no HTTP API for Homepage to poll. Either remove the speedtest widget and use Grafana for network stats, or replace the container with `lscr.io/linuxserver/speedtest-tracker` which is Homepage-compatible.

---

## settings.yaml

```yaml
title: Home Server
theme: dark
color: slate
headerStyle: clean
layout:
  Media:
    style: row
    columns: 2
  Photos & Files:
    style: row
    columns: 2
  Monitoring & Network:
    style: row
    columns: 2
```

---

## Known Issues & Fixes

### Host Validation Error
```
error: Host validation failed for: deathstar
```
**Fix:** Add to environment in compose:
```
HOMEPAGE_ALLOWED_HOSTS=deathstar,deathstar:80,${LOCAL_TAIL_HOST},${LOCAL_TAIL_HOST}:80
```

### Docker Socket Permission Error
```
error: connect EACCES /var/run/docker.sock
```
**Fix:** Check docker GID with `stat /var/run/docker.sock`, then add to compose:
```yaml
group_add:
  - "983"  # replace with your actual GID
```
Verify it worked with: `docker exec homepage id` — look for `983` in the groups list.

### Pi-hole Widget API Key Error
Get your key:
```bash
docker exec pihole pihole -a -g
```
Or: Pi-hole UI → Settings → API → Show API token.

### Weather Not Showing
Requires a free API key from [weatherapi.com](https://www.weatherapi.com). Add as `apiKey:` in `widgets.yaml`.

---

## Useful Commands

```bash
# View live logs
docker logs homepage --follow

# Force recreate after compose changes
docker compose down homepage && docker compose up -d homepage

# Verify env vars loaded
docker exec homepage env | grep HOMEPAGE

# Verify docker socket group access
docker exec homepage id
```

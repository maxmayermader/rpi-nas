# Jellyfin Setup on Raspberry Pi NAS

## Docker Compose Block

```yaml
jellyfin:
  image: lscr.io/linuxserver/jellyfin:latest
  container_name: jellyfin
  environment:
    - PUID=${USER_ID}
    - PGID=${GROUP_ID}
    - TZ=${TZ}
    - JELLYFIN_PublishedServerUrl=100.x.x.x  # Use Tailscale IP (run: tailscale ip -4)
  volumes:
    - ${PATH_TO_DISK}/appdata/jellyfin:/config
    - ${PATH_TO_DISK}/media/tv:/data/tvshows
    - ${PATH_TO_DISK}/media/movies:/data/movies
  ports:
    - 8096:8096
    - 8920:8920  # Optional HTTPS
  devices:
    - /dev/dri:/dev/dri  # Hardware acceleration (Pi 5)
  restart: unless-stopped
```

> **Note:** Do not include `/dev/vchiq` — it does not exist on the Pi 5 and will cause a startup error.

---

## Host Setup

Add your user to the `video` and `render` groups so the container can access `/dev/dri`:

```bash
sudo usermod -aG video,render max
newgrp render  # or log out and back in
```

Verify with:
```bash
groups max  # should include video and render
```

---

## Starting the Container

```bash
docker compose up -d jellyfin
```

Access the web UI at: `http://<your-pi-ip>:8096`

- Local: `http://192.168.68.62:8096`
- Remote (Tailscale): `http://100.x.x.x:8096`

---

## First-Time Setup Wizard

1. **Create admin account** — pick a strong password
2. **Add media libraries:**
   - TV Shows → `/data/tvshows`
   - Movies → `/data/movies`
3. **Metadata language** — set to preference
4. **Remote access** — leave enabled
5. **Server name** — cosmetic only, keep default or customize freely

---

## Hardware Transcoding (Pi 5)

In the Jellyfin dashboard go to **Dashboard → Playback → Transcoding**:

- Set hardware acceleration to **V4L2**
- Select `/dev/dri/renderD128` as the device
- Enable codecs: **H.264** (required), **H.265** (recommended if your media uses it)

---

## Tailscale

Use your Pi's Tailscale IP for `JELLYFIN_PublishedServerUrl` so remote clients are handed the correct address for playback.

```bash
tailscale ip -4  # get your Pi's Tailscale IP
```

If you also use Jellyfin on your local network, consider using your **MagicDNS hostname** instead (e.g. `deathstar.tail12345.ts.net`) so one value works both locally and remotely.

---

## YAML Gotchas Encountered

- `${PATH_TO_DATA}` in volume paths should be `${PATH_TO_DISK}` to match the rest of the compose file
- `restart: always` on the `telegraf` service was misaligned outside its service block — caused `services.restart must be a mapping` error
- The `version:` field at the top of `docker-compose.yml` is deprecated — safe to remove (causes a harmless warning)

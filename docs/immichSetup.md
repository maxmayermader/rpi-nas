# Immich Setup Guide

## 1. Docker Compose Services

Add the following services to your existing `docker-compose.yml`:

```yaml
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    volumes:
      - ${UPLOAD_LOCATION}:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    environment:
      - DB_HOSTNAME=immich_postgres
      - DB_USERNAME=immich
      - DB_PASSWORD=${IMMICH_DB_PASSWORD}
      - DB_DATABASE_NAME=immich
      - REDIS_HOSTNAME=immich_redis
    ports:
      - 2283:2283
    depends_on:
      - immich_redis
      - immich_postgres
    restart: unless-stopped

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
    volumes:
      - immich_model_cache:/cache
    restart: unless-stopped

  immich_redis:
    container_name: immich_redis
    image: docker.io/valkey/valkey:9
    restart: unless-stopped

  immich_postgres:
    container_name: immich_postgres
    image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
    environment:
      - POSTGRES_PASSWORD=${IMMICH_DB_PASSWORD}
      - POSTGRES_USER=immich
      - POSTGRES_DB=immich
    volumes:
      - ${IMMICH_DB_DATA_LOCATION}:/var/lib/postgresql/data
    restart: unless-stopped
```

Add to the `volumes:` section at the bottom of your compose file:

```yaml
  immich_model_cache:
```

---

## 2. Environment Variables

Add the following to your `.env` file:

```env
UPLOAD_LOCATION=/path/to/your/disk/immich/library
IMMICH_DB_DATA_LOCATION=/path/to/your/disk/appdata/immich/postgres
IMMICH_DB_PASSWORD=changeme_use_a_strong_password
IMMICH_VERSION=release
```

> **Note:** `IMMICH_DB_DATA_LOCATION` must point to **local SSD storage** — network shares are not supported for the Postgres database.

---

## 3. Start the Containers

```bash
docker compose up -d immich-server immich-machine-learning immich_redis immich_postgres
```

Verify all four containers are running:

```bash
docker compose ps
```

Check logs if something looks off:

```bash
docker compose logs immich-server --follow
```

---

## 4. First-Time Web Setup

1. Open a browser and navigate to `http://<your-pi-ip>:2283`
   - Or use your Tailscale hostname/IP for remote access
2. Click **Getting Started**
3. Register your admin account — the first user to register becomes admin
4. Set your instance name and profile

---

## 5. Mobile App

1. Download **Immich** from the App Store or Google Play
2. On first launch, enter your server URL: `http://<your-pi-ip>:2283`
3. Log in with your admin account
4. Enable **auto-backup** in the app settings to sync your camera roll

---

## 6. Important Notes

- **Postgres image:** Immich requires its own custom Postgres image (`ghcr.io/immich-app/postgres`) with VectorChord support — you cannot reuse your existing `nextcloud_postgres` container.
- **ML models:** The machine learning container downloads its models on first use. Facial recognition and smart search will be unavailable for a few minutes after first launch.
- **Initial processing:** Expect high CPU usage on the Pi while Immich indexes an existing photo library — this is normal and will settle down.
- **Port:** Immich runs on port `2283` by default, which should not conflict with other services in your stack.

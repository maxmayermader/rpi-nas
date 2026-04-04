# Nextcloud Setup Guide (timoknapp/rpi-nas)

## Overview

Nextcloud is an optional component in the rpi-nas stack, running on port **8081**. It uses a PostgreSQL database container for persistent storage.

---

## Prerequisites

- Docker and Docker Compose installed on your Raspberry Pi
- The `rpi-nas` repo cloned and your `docker-compose.yml` configured (placeholders replaced)

---

## Steps

### 1. Configure `docker-compose.yml`

Before starting the stack, make sure the following placeholders are filled in:

- `${PATH_TO_DISK}` → your actual mount path (e.g. `/mnt/qnap`)
- `${USER_ID}` and `${GROUP_ID}` → output of `id $(whoami)` on your Pi
- Postgres password → set a password for the `postgres` user in the db service

Nextcloud is optional — make sure it is **uncommented** in the compose file.

### 2. Start the Stack

```bash
docker-compose up -d
```

### 3. Open the Nextcloud Setup Page

Navigate to:

```
http://<IP-OF-YOUR-PI>:8081
```

### 4. Create the Admin Account

Fill in a username and password for your Nextcloud admin account.

### 5. Configure the Database

When prompted to choose a database, select **PostgreSQL** and enter:

| Field         | Value                  |
|---------------|------------------------|
| Database user | `postgres`             |
| Password      | *(your set password)*  |
| Database name | `nextcloud` *(or as configured)* |
| **Host**      | `nextcloud_postgres`   |
| Port          | `5432`                 |

> **Important:** The host must be `nextcloud_postgres` (the Docker container/service name), **not** `localhost` or `127.0.0.1`. Using `localhost` will cause a connection refused error because containers cannot reach each other that way.

### 6. Finish Setup

Click **Finish setup**. Nextcloud will initialize its database and redirect you to the dashboard.

---

## Troubleshooting

**Error: `SQLSTATE[08006] connection refused` on localhost**

This means the DB host was set to `localhost`. Fix it by editing the Nextcloud config file directly:

```bash
# Find the config volume path, then edit:
nano <nextcloud-data-path>/config/config.php
```

Change:
```php
'dbhost' => 'localhost',
```
To:
```php
'dbhost' => 'nextcloud_postgres',
```

Or wipe and restart fresh:
```bash
docker-compose down -v
docker-compose up -d
```
Then redo the setup with the correct host.

---

## Access

Once set up, Nextcloud is available at:

```
http://<IP-OF-YOUR-PI>:8081
```

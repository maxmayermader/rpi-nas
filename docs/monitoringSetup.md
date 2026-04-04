# Monitoring Stack Setup (Telegraf + InfluxDB v2 + Grafana)

## Overview

This stack collects system metrics from your Raspberry Pi and displays them in Grafana dashboards.

| Container   | Role                              | Port  |
|-------------|-----------------------------------|-------|
| `telegraf`  | Collects metrics from the Pi      | —     |
| `influxdb`  | Stores time-series metric data    | 8086  |
| `grafana`   | Visualizes metrics in dashboards  | 3000  |
| `speedtest` | Runs hourly internet speed tests  | —     |

---

## Step 1: Configure Telegraf

Your compose mounts `${PATH_TO_DISK}/appdata/monitoring/telegraf` as the config directory.

```bash
mkdir -p /mnt/qnap/appdata/monitoring/telegraf
nano /mnt/qnap/appdata/monitoring/telegraf/telegraf.conf
```

Paste the following config:

```toml
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  flush_interval = "10s"

# Output to InfluxDB v2
[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "YOUR_API_TOKEN"
  organization = "homelab"
  bucket = "telegraf"

# CPU
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false

# RAM
[[inputs.mem]]

# Disk usage
[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

# Disk I/O
[[inputs.diskio]]

# Network
[[inputs.net]]

# System load
[[inputs.system]]

# Processes
[[inputs.processes]]

# CPU Temperature (Raspberry Pi)
[[inputs.file]]
  files = ["/sys/class/thermal/thermal_zone0/temp"]
  name_override = "cpu_temperature"
  data_format = "value"
  data_type = "integer"
```

Also add the thermal sensor mount to the `telegraf` service in `docker-compose.yml`:

```yaml
volumes:
  - /sys/class/thermal/thermal_zone0/temp:/sys/class/thermal/thermal_zone0/temp:ro
```

---

## Step 2: Start the Stack

```bash
docker-compose up -d telegraf influxdb grafana speedtest
```

---

## Step 3: Set Up InfluxDB v2

> **Note:** The stack uses InfluxDB v2, which is significantly different from v1. It uses organizations, buckets, and API tokens instead of databases and passwords.

Run the interactive setup:

```bash
docker exec -it influxdb influx setup
```

When prompted, enter:

| Field            | Value                     |
|------------------|---------------------------|
| Username         | `admin`                   |
| Password         | *(choose one)*            |
| Org name         | `homelab`                 |
| Bucket name      | `telegraf`                |
| Retention period | `0` (unlimited)           |

Then retrieve your API token:

```bash
docker exec -it influxdb influx auth list
```

Copy the token — you'll need it for both Telegraf and Grafana.

Go back and paste it into `telegraf.conf` where it says `YOUR_API_TOKEN`, then restart Telegraf:

```bash
docker-compose restart telegraf
```

---

## Step 4: Create a DBRP Mapping (for InfluxQL / Dashboard 10578)

Dashboard 10578 uses InfluxQL, which requires a v1 compatibility mapping in InfluxDB v2.

```bash
# Get your bucket ID
docker exec -it influxdb influx bucket list

# Create the DBRP mapping (replace YOUR_BUCKET_ID)
docker exec -it influxdb influx v1 dbrp create \
  --db telegraf \
  --rp autogen \
  --bucket-id YOUR_BUCKET_ID \
  --default
```

Then create a v1-compatible auth credential:

```bash
docker exec -it influxdb influx v1 auth create \
  --username telegraf \
  --password yourpassword \
  --org homelab \
  --read-bucket YOUR_BUCKET_ID
```

---

## Step 5: Configure Grafana Datasource

1. Open Grafana at `http://<PI-IP>:3000`
2. Login: `admin` / `admin` (you'll be prompted to change it)
3. Go to **Connections → Data Sources → Add data source**
4. Choose **InfluxDB** and set:

| Field                  | Value                        |
|------------------------|------------------------------|
| Query Language         | `InfluxQL`                   |
| URL                    | `http://influxdb:8086`       |
| Basic Auth             | ON                           |
| Basic Auth — Username  | `telegraf`                   |
| Basic Auth — Password  | *(password from Step 4)*     |
| Custom HTTP Header     | `Authorization`              |
| Header Value           | `Token YOUR_V2_API_TOKEN`    |
| Database               | `telegraf`                   |

5. Click **Save & Test** — should show green

---

## Step 6: Import Dashboard 10578

1. Go to **Dashboards → Import**
2. Enter ID `10578`
3. Select your InfluxDB datasource
4. Click **Import**

You'll get panels for CPU usage, RAM, disk, network I/O, and system load out of the box.

---

## Metrics Collected

| Metric         | Source                                    |
|----------------|-------------------------------------------|
| CPU usage      | `inputs.cpu`                              |
| RAM usage      | `inputs.mem`                              |
| Disk usage     | `inputs.disk`                             |
| Disk I/O       | `inputs.diskio`                           |
| Network        | `inputs.net`                              |
| CPU temp       | `/sys/class/thermal/thermal_zone0/temp`   |
| Internet speed | `speedtest` container (runs every hour)   |

---

## Troubleshooting

**Telegraf not sending data**
```bash
docker logs telegraf
```
Look for auth errors — usually means the token in `telegraf.conf` is wrong or missing.

**Grafana datasource "unauthorized"**
- Make sure query language is set to `InfluxQL` (not Flux)
- Confirm the `Authorization: Token ...` custom header is set correctly

**No temperature data**
- Confirm the thermal file is mounted into the Telegraf container in `docker-compose.yml`
- Check it exists on the host: `cat /sys/class/thermal/thermal_zone0/temp`

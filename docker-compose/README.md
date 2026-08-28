# Docker Compose - Core Infrastructure

Minimal local stack for Pamawas development: **PostgreSQL + 6 Pamawas services only**.

Observability (Prometheus, Loki, Tempo, Grafana) is **external** — configure via environment variables.

## Quick Start

```bash
cd docker-compose
cp .env.example .env
# Edit .env with your keys (LLM_API_KEY required, observability URLs optional)
docker compose up -d
```

## Services Included

| Service | Port | Description |
|---------|------|-------------|
| postgresql | 5432 | Primary database |
| pamawas-migrations | 8080 | Schema migration runner (one-shot) |
| pamawas-ingest | 8080 | Webhook ingestion |
| pamawas-correlator | 8081 | Event correlation |
| pamawas-investigator | 8082 | LLM investigation |
| pamawas-reporter | 8083 | Report generation |
| pamawas-scheduler | 8084 | Cron scheduling |

## Required Environment Variables

```bash
# Database
POSTGRES_USER=pamawas
POSTGRES_PASSWORD=pamawas
POSTGRES_DB=pamawas

# LLM (investigator won't work without this)
LLM_API_KEY=your_openai_api_key_here
```

## Optional: External Observability

If you have a Grafana stack running elsewhere (separate host, Docker network, or managed service), set these to enable metrics/logs/traces:

```bash
# Metrics scraping target for your Prometheus
PROMETHEUS_URL=http://your-prometheus:9090

# Logs ingestion for your Loki
LOKI_URL=http://your-loki:3100

# Traces OTLP endpoint for your Tempo
TEMPO_OTLP_ENDPOINT=your-tempo:4317

# Grafana URL (for reference/dashboard links)
GRAFANA_URL=http://your-grafana:3000
```

**If left empty**, observability features are gracefully disabled:
- No metrics exported (Prometheus scrapes will 404)
- No traces sent (OTel exporter no-op)
- Investigator tools (Prometheus/Loki queries) will fail unless URLs provided

## Optional: Delivery Channels

```bash
DISCORD_WEBHOOK_URL=
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
EMAIL_SMTP_HOST=
EMAIL_SMTP_PORT=587
EMAIL_USERNAME=
EMAIL_PASSWORD=
EMAIL_FROM=
EMAIL_TO=
```

## Access URLs (Local)

- **Ingest**: http://localhost:8080
- **Correlator**: http://localhost:8081
- **Investigator**: http://localhost:8082
- **Reporter**: http://localhost:8083
- **Scheduler**: http://localhost:8084

Health checks on all services: `GET /healthz`, `GET /ready`
Metrics (if Prometheus configured): `GET /metrics`

## Development Workflow

```bash
# 1. Start database
docker compose up -d postgresql

# 2. Run migrations (automatic via pamawas-migrations service)
docker compose up -d pamawas-migrations

# 3. Start app services
docker compose up -d pamawas-ingest pamawas-correlator pamawas-reporter pamawas-scheduler

# 4. (Optional) Start investigator with LLM
docker compose up -d pamawas-investigator

# 5. Test webhook
curl -X POST http://localhost:8080/webhook/generic \
  -H "Content-Type: application/json" \
  -d '{"source": "test", "data": {"message": "hello"}}'
```

## Connecting to External Observability

### Same Docker Host (different compose project)
```bash
# In .env
PROMETHEUS_URL=http://host.docker.internal:9090
LOKI_URL=http://host.docker.internal:3100
TEMPO_OTLP_ENDPOINT=host.docker.internal:4317
```

### Remote Host
```bash
# In .env
PROMETHEUS_URL=http://obs.example.com:9090
LOKI_URL=http://obs.example.com:3100
TEMPO_OTLP_ENDPOINT=obs.example.com:4317
```

### Kubernetes (Port-forward)
```bash
# Terminal 1: kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Terminal 2: kubectl port-forward -n monitoring svc/loki 3100:3100
# Terminal 3: kubectl port-forward -n monitoring svc/tempo 4317:4317
# In .env
PROMETHEUS_URL=http://host.docker.internal:9090
LOKI_URL=http://host.docker.internal:3100
TEMPO_OTLP_ENDPOINT=host.docker.internal:4317
```

## Full Stack (Legacy)

The previous full-stack compose (with embedded Prometheus/Loki/Tempo/Grafana) is backed up at:
```
docker-compose.yml.full-backup
```

To use it:
```bash
cp docker-compose.yml.full-backup docker-compose.yml
docker compose up -d
```

## Verification

```bash
# Check all services healthy
docker compose ps

# Check logs
docker compose logs -f pamawas-ingest

# Test ingest endpoint
curl http://localhost:8080/healthz
curl http://localhost:8080/ready

# Test metrics (if Prometheus configured)
curl http://localhost:8080/metrics | head -20
```
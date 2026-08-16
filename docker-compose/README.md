# Docker Compose - Local Development

Full local stack for Pamawas development including all infrastructure dependencies.

## Quick Start

```bash
cd docker-compose
cp .env.example .env
# Edit .env with your keys (LLM_API_KEY, DISCORD_WEBHOOK_URL, etc.)
docker-compose up -d
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| postgresql | 5432 | Primary database |
| pamawas-migrations | 8080 | Schema migration runner |
| prometheus | 9090 | Metrics collection |
| loki | 3100 | Log aggregation |
| tempo | 3200/4317 | Distributed tracing |
| grafana | 3000 | Visualization |
| pamawas-ingest | 8080 | Webhook ingestion |
| pamawas-correlator | 8081 | Event correlation |
| pamawas-investigator | 8082 | LLM investigation |
| pamawas-reporter | 8083 | Report generation |
| pamawas-scheduler | 8084 | Cron scheduling |

## Access URLs

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100
- **Tempo**: http://localhost:3200
- **Ingest**: http://localhost:8080
- **Correlator**: http://localhost:8081
- **Investigator**: http://localhost:8082
- **Reporter**: http://localhost:8083
- **Scheduler**: http://localhost:8084

## Configuration

See `.env.example` for all environment variables. Key variables:

```bash
# Required
POSTGRES_USER=pamawas
POSTGRES_PASSWORD=pamawas
POSTGRES_DB=pamawas
LLM_API_KEY=your_openai_key

# Optional delivery
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

## Development Workflow

```bash
# 1. Start infrastructure
docker-compose up -d postgresql prometheus loki tempo

# 2. Run migrations (automatic via pamawas-migrations service)
docker-compose up -d pamawas-migrations

# 3. Start app services
docker-compose up -d pamawas-ingest pamawas-correlator pamawas-reporter pamawas-scheduler

# 4. (Optional) Start investigator with LLM
docker-compose up -d pamawas-investigator

# 5. Test webhook
curl -X POST http://localhost:8080/webhook/generic \
  -H "Content-Type: application/json" \
  -d '{"timestamp":"2026-08-13T02:14:23Z","service":"payment-api","title":"High latency"}'

# 6. Trigger correlation
curl -X POST http://localhost:8081/trigger

# 7. Trigger report
curl -X POST http://localhost:8083/report -H "Content-Type: application/json" -d '{}'
```

## Grafana Dashboards

Access Grafana at http://localhost:3000 (admin/admin). Pre-configured datasources:
- Prometheus (http://prometheus:9090)
- Loki (http://loki:3100)
- Tempo (http://tempo:3200)

## Distributed Tracing with Tempo

1. Open Grafana → Explore
2. Select **Tempo** datasource
3. Search by service name: `pamawas-ingest`, `pamawas-correlator`, etc.

## Notes

- This compose file is for **development only**
- For production, use Kubernetes manifests or Helm chart
- Some services (investigator) require LLM API keys to function fully
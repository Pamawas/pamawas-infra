# pamawas-infra

**Infrastructure Deployments** — Docker Compose (local), Kubernetes manifests, Helm chart for production.

---

## Deployment Options

| Option | Use Case |
|--------|----------|
| **Docker Compose (Core)** | Local development with PostgreSQL + Pamawas services only. Observability is external. |
| **Docker Compose (Full)** | Legacy full stack with embedded Prometheus, Loki, Tempo, Grafana (backed up). |
| **Kubernetes (Plain)** | Raw manifests for direct `kubectl apply` — assumes external PostgreSQL, Prometheus, Loki, Tempo, Grafana. |
| **Helm Chart** | Production deployments with templating, values, dependencies — assumes external dependencies. |

---

## 1. Docker Compose (Core - Recommended for Local Dev)

**Core infra only**: PostgreSQL + 6 Pamawas services. Observability stack (Prometheus, Loki, Tempo, Grafana) runs **externally** — connect via environment variables.

```bash
cd docker-compose
cp .env.example .env
# Edit .env: LLM_API_KEY is REQUIRED; observability URLs optional
docker compose up -d
```

**Services included:**
- **Core**: PostgreSQL, pamawas-migrations, pamawas-ingest, pamawas-correlator, pamawas-investigator, pamawas-reporter, pamawas-scheduler
- **Observability**: External (configure via `PROMETHEUS_URL`, `LOKI_URL`, `TEMPO_OTLP_ENDPOINT`)

See [docker-compose/README.md](docker-compose/README.md) for details.

### Access URLs (Local)
- **Ingest**: http://localhost:8080
- **Correlator**: http://localhost:8081
- **Investigator**: http://localhost:8082
- **Reporter**: http://localhost:8083
- **Scheduler**: http://localhost:8084

---

## 2. Docker Compose (Full Stack - Legacy)

Full stack with embedded observability. Backed up at `docker-compose/docker-compose.yml.full-backup`.

```bash
cd docker-compose
cp docker-compose.yml.full-backup docker-compose.yml
cp .env.example .env
docker compose up -d
```

**Services included:**
- Everything in Core + Prometheus (9090), Loki (3100), Tempo (3200/4317), Grafana (3000)

---

## 3. Kubernetes (Plain Manifests)

Assumes you have deployed: **PostgreSQL, Prometheus, Loki, Tempo, Grafana** (via operators, Helm, or managed services).

```bash
cd k8s
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f deployments/
kubectl apply -f services.yaml
kubectl apply -f ingress.yaml
```

### Prerequisites (external to this repo)
- PostgreSQL 16+ (Cloud SQL, RDS, or operator)
- Prometheus (kube-prometheus-stack or similar)
- Loki (Grafana Loki Stack)
- Tempo (Grafana Tempo Stack)
- Grafana (with datasources pre-configured)

---

## 4. Helm Chart (Production)

```bash
cd helm/pamawas
helm dependency update
helm install pamawas . -n pamawas --create-namespace -f values.yaml
```

### Key Values
```yaml
# values.yaml
postgresql:
  enabled: false  # Use external PostgreSQL
  externalHost: postgres.example.com

observability:
  prometheusUrl: http://prometheus.monitoring:9090
  lokiUrl: http://loki.monitoring:3100
  tempoOtlpEndpoint: tempo.monitoring:4317

llm:
  apiKey: "your-key"
  baseUrl: "https://api.openai.com/v1"
  model: "gpt-4o-mini"
```

---

## Directory Structure

```
pamawas-infra/
├── docker-compose/
│   ├── docker-compose.yml          # Core infra (PostgreSQL + services)
│   ├── docker-compose.yml.full-backup  # Legacy full stack
│   ├── .env.example                # Environment template
│   └── README.md
├── k8s/                            # Plain Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployments/
│   ├── services.yaml
│   └── ingress.yaml
└── helm/pamawas/                   # Helm chart
    ├── Chart.yaml
    ├── values.yaml
    ├── values-prod.yaml
    └── templates/
```

---

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `POSTGRES_USER` | Yes | `pamawas` | Database user |
| `POSTGRES_PASSWORD` | Yes | `pamawas` | Database password |
| `POSTGRES_DB` | Yes | `pamawas` | Database name |
| `LLM_API_KEY` | Yes* | — | OpenAI-compatible API key (*required for investigator) |
| `LLM_BASE_URL` | No | `https://api.openai.com/v1` | LLM API base URL |
| `LLM_MODEL` | No | `gpt-4o-mini` | LLM model |
| `PROMETHEUS_URL` | No | — | External Prometheus URL (for investigator tools) |
| `LOKI_URL` | No | — | External Loki URL (for investigator tools) |
| `TEMPO_OTLP_ENDPOINT` | No | — | External Tempo OTLP gRPC endpoint |
| `GRAFANA_URL` | No | — | External Grafana URL (reference) |
| `DISCORD_WEBHOOK_URL` | No | — | Discord delivery webhook |
| `TELEGRAM_BOT_TOKEN` | No | — | Telegram bot token |
| `TELEGRAM_CHAT_ID` | No | — | Telegram chat ID |
| `EMAIL_SMTP_HOST` | No | — | SMTP host |
| `EMAIL_SMTP_PORT` | No | `587` | SMTP port |
| `EMAIL_USERNAME` | No | — | SMTP username |
| `EMAIL_PASSWORD` | No | — | SMTP password |
| `EMAIL_FROM` | No | — | From address |
| `EMAIL_TO` | No | — | To address |
# pamawas-infra

**Infrastructure Deployments** — Docker Compose (local), Kubernetes manifests, Helm chart for production.

---

## Deployment Options

| Option | Use Case |
|--------|----------|
| **Docker Compose** | Local development with full stack (PG, Prom, Loki, Tempo, Grafana) |
| **Kubernetes (Plain)** | Raw manifests for direct `kubectl apply` |
| **Helm Chart** | Production deployments with templating, values, dependencies |

---

## 1. Docker Compose (Local Development)

Full stack including all dependencies:

```bash
cd docker-compose
cp .env.example .env
# Edit .env with your keys (LLM_API_KEY, etc.)
docker-compose up -d
```

**Services included:**
- **Infrastructure**: PostgreSQL, Prometheus, Loki, Tempo, Grafana
- **Applications**: pamawas-ingest, pamawas-correlator, pamawas-investigator, pamawas-reporter, pamawas-scheduler, pamawas-schema (migration runner)

See [docker-compose/README.md](docker-compose/README.md) for details.

---

## 2. Kubernetes (Plain Manifests)

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

| Component | Example Deployment |
|-----------|-------------------|
| **PostgreSQL** | Cloud SQL, RDS, `bitnami/postgresql` Helm, `cnpg` operator |
| **Prometheus** | `prometheus-community/kube-prometheus-stack` |
| **Loki** | `grafana/loki-stack` Helm, Grafana Agent |
| **Tempo** | `grafana/tempo` Helm, Grafana Agent |
| **Grafana** | Included in kube-prometheus-stack |

### Configuration via ConfigMap/Secret

```yaml
# configmap.yaml - non-sensitive config
# secret.yaml - sensitive values (DB password, API keys, webhook URLs)
```

See [k8s/README.md](k8s/README.md) for detailed configuration.

---

## 3. Helm Chart (Recommended for Production)

```bash
cd helm/pamawas

# Install with custom values
helm install pamawas . -n pamawas --create-namespace -f values-prod.yaml

# Or install with observability stack dependencies
helm install pamawas . -n pamawas --create-namespace --set global.deployObservabilityStack=true
```

### Chart Structure

```
helm/pamawas/
├── Chart.yaml
├── values.yaml              # Default values
├── values-prod.yaml         # Production example
├── templates/
│   ├── _helpers.tpl
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── serviceaccount.yaml
│   ├── deployments/
│   │   ├── ingest.yaml
│   │   ├── correlator.yaml
│   │   ├── investigator.yaml
│   │   ├── reporter.yaml
│   │   ├── scheduler.yaml
│   │   └── schema-migration.yaml
│   ├── services.yaml
│   ├── ingress.yaml
│   ├── servicemonitor.yaml  # Prometheus scraping
│   └── podmonitor.yaml      # Loki/Tempo (optional)
├── charts/                  # Sub-charts (optional)
└── README.md
```

### Key Values

```yaml
# values.yaml
global:
  imageRegistry: ghcr.io
  imagePullSecrets: []
  deployObservabilityStack: false  # Set true to deploy Prom/Loki/Tempo via subcharts

pamawas:
  ingest:
    enabled: true
    replicaCount: 2
    resources: {}
  correlator:
    enabled: true
    replicaCount: 1
  investigator:
    enabled: true
    replicaCount: 1
  reporter:
    enabled: true
    replicaCount: 1
  scheduler:
    enabled: true
    replicaCount: 1
  schemaMigration:
    enabled: true

# External dependencies (user-managed)
external:
  postgresql:
    host: "postgresql.example.com"
    port: 5432
    database: "pamawas"
    existingSecret: "pamawas-postgresql"  # keys: username, password
  tempo:
    endpoint: "tempo.example.com:4317"
  loki:
    endpoint: "http://loki.example.com:3100"
  prometheus:
    endpoint: "http://prometheus.example.com:9090"

# Delivery credentials
delivery:
  discordWebhookUrl: ""
  telegramBotToken: ""
  telegramChatId: ""
  email:
    smtpHost: ""
    smtpPort: 587
    username: ""
    password: ""
    from: ""
    to: ""

# LLM (investigator)
llm:
  baseUrl: "https://api.openai.com/v1"
  apiKey: "***"
  model: "gpt-4o-mini"
```

### Prometheus Scraping

ServiceMonitors included for each service. Requires `prometheus-operator` CRDs.

```bash
# Verify ServiceMonitors
kubectl get servicemonitor -n pamawas
```

### Ingress

Ingress resources included for HTTP endpoints. Configure `ingressClassName` and TLS in values.

---

## Directory Structure

```
pamawas-infra/
├── docker-compose/              # Local dev with full stack
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── tempo.yaml
│   ├── prometheus.yml
│   ├── loki-config.yml
│   ├── grafana-datasources.yml
│   └── README.md
├── k8s/                         # Plain Kubernetes manifests
│   ├── README.md
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployments/
│   │   ├── ingest.yaml
│   │   ├── correlator.yaml
│   │   ├── investigator.yaml
│   │   ├── reporter.yaml
│   │   ├── scheduler.yaml
│   │   └── schema-migration.yaml
│   ├── services.yaml
│   ├── servicemonitor.yaml
│   └── ingress.yaml
└── helm/
    └── pamawas/                 # Helm chart
        ├── Chart.yaml
        ├── values.yaml
        ├── values-prod.yaml
        ├── templates/
        │   ├── _helpers.tpl
        │   ├── namespace.yaml
        │   ├── configmap.yaml
        │   ├── secret.yaml
        │   ├── serviceaccount.yaml
        │   ├── deployments/
        │   ├── services.yaml
        │   ├── servicemonitor.yaml
        │   └── ingress.yaml
        └── README.md
```

---

## Quick Start

### Local (Docker Compose)
```bash
cd docker-compose
cp .env.example .env
docker-compose up -d
```

### Kubernetes (Plain)
```bash
cd k8s
kubectl apply -f .
```

### Helm (Production)
```bash
cd helm/pamawas
helm dependency update
helm install pamawas . -n pamawas --create-namespace -f values-prod.yaml
```

---

## Environment Variables Reference

All services share common environment variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Tempo OTLP gRPC endpoint | Yes |
| `ENVIRONMENT` | `development` \| `production` | No (default: development) |
| `LOG_LEVEL` | `debug` \| `info` \| `warn` \| `error` | No (default: info) |

Service-specific variables documented in each component's README.

---

## Related

- **Root README**: [../README.md](../README.md)
- **Component READMEs**: [../pamawas-ingest/](../pamawas-ingest/) [../pamawas-correlator/](../pamawas-correlator/) [../pamawas-investigator/](../pamawas-investigator/) [../pamawas-reporter/](../pamawas-reporter/) [../pamawas-scheduler/](../pamawas-scheduler/) [../pamawas-schema/](../pamawas-schema/)
- **Docker Images**: `ghcr.io/yoganovvaindra/pamawas-*`
# Pamawas Helm Chart

Helm chart for deploying the Pamawas AI Infrastructure Incident Investigator platform.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.10+
- Prometheus Operator CRDs (for ServiceMonitors)
- cert-manager (for TLS via Ingress)
- External dependencies deployed separately:
  - PostgreSQL
  - Prometheus + Prometheus Operator
  - Loki
  - Tempo
  - Grafana

## Install

```bash
# Add repo (if published)
helm repo add pamawas https://pamawas.github.io/helm-charts
helm repo update

# Or install from local chart
cd helm/pamawas
helm dependency update
helm install pamawas . -n pamawas --create-namespace -f values-prod.yaml
```

## Configuration

### Required Values

Create a `values-prod.yaml` with your configuration:

```yaml
global:
  imageRegistry: ghcr.io
  
# External dependencies
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

# LLM (investigator)
llm:
  baseUrl: "https://api.openai.com/v1"
  apiKey: "your_openai_key"
  model: "gpt-4o-mini"

# Delivery (reporter)
delivery:
  discordWebhookUrl: "https://discord.com/api/webhooks/..."
  telegramBotToken: "your_bot_token"
  telegramChatId: "your_chat_id"
  email:
    smtpHost: "smtp.example.com"
    smtpPort: 587
    username: "reporter@example.com"
    password: "smtp_password"
    from: "reporter@example.com"
    to: "team@example.com"

# Ingress
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: pamawas.example.com
      paths:
        - path: /webhook
          service: ingest
        - path: /trigger
          service: correlator
        - path: /investigate
          service: investigator
        - path: /report
          service: reporter
        - path: /trigger/daily
          service: scheduler
  tls:
    - secretName: pamawas-tls
      hosts:
        - pamawas.example.com

# ServiceMonitors (requires prometheus-operator)
serviceMonitors:
  enabled: true
  release: prometheus
```

### Install with Custom Values

```bash
helm install pamawas . -n pamawas --create-namespace -f values-prod.yaml
```

### Upgrade

```bash
helm upgrade pamawas . -n pamawas -f values-prod.yaml
```

### Uninstall

```bash
helm uninstall pamawas -n pamawas
```

## Chart Structure

```
pamawas/
├── Chart.yaml
├── values.yaml
├── values-prod.yaml          # Create this for production
├── .helmignore
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
│   ├── servicemonitor.yaml
│   └── ingress.yaml
└── README.md
```

## Services

| Component | Deployment | Service | Probes | Metrics |
|-----------|------------|---------|--------|---------|
| ingest | Deployment (2) | ClusterIP | /healthz, /ready | ✅ |
| correlator | Deployment (1) | ClusterIP | /healthz, /ready | ✅ |
| investigator | Deployment (1) | ClusterIP | /healthz, /ready | ✅ |
| reporter | Deployment (1) | ClusterIP | /healthz, /ready | ✅ |
| scheduler | Deployment (1) | ClusterIP | /healthz, /ready | ✅ |
| schema-migration | Job | - | - | - |

## Observability

All services include:
- **Prometheus ServiceMonitors** (requires prometheus-operator)
- **OpenTelemetry tracing** to Tempo (OTLP gRPC)
- **Structured JSON logging** with trace context
- **Health/Readiness endpoints** for Kubernetes probes

## ServiceAccount & RBAC

Chart creates a `pamawas` ServiceAccount. Add RBAC bindings if your cluster requires specific permissions.

## Network Policies

Not included by default. Enable `networkPolicy.enabled: true` to add default deny-all with allow rules for service-to-service communication.

## Values Reference

### Global
| Key | Description | Default |
|-------|-------------|---------|
| `global.imageRegistry` | Container registry | `ghcr.io` |
| `global.imagePullSecrets` | Pull secrets | `[]` |
| `global.deployObservabilityStack` | Deploy Prom/Loki/Tempo via subcharts | `false` |

### Service Configuration
Each service has `enabled`, `replicaCount`, `image`, `resources`, `config`, `probes`.

### External Dependencies
| Key | Description |
|-------|-------------|
| `external.postgresql` | PostgreSQL connection (host, port, db, existingSecret) |
| `external.tempo.endpoint` | Tempo OTLP gRPC endpoint |
| `external.loki.endpoint` | Loki HTTP endpoint |
| `external.prometheus.endpoint` | Prometheus HTTP endpoint |

### Delivery & LLM
| Key | Description |
|-------|-------------|
| `delivery.discordWebhookUrl` | Discord webhook |
| `delivery.telegramBotToken` | Telegram bot token |
| `delivery.telegramChatId` | Telegram chat ID |
| `delivery.email` | SMTP config |
| `llm.baseUrl` | LLM API base URL |
| `llm.apiKey` | LLM API key |
| `llm.model` | LLM model name |

## Development

```bash
# Lint
helm lint .

# Template render (dry-run)
helm template test-release . -f values-prod.yaml --debug

# Install CRDs first (if needed)
kubectl apply -f https://github.com/prometheus-operator/prometheus-operator/releases/latest/download/bundle.yaml
kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.yaml
```

## Notes

- Images pulled from `ghcr.io/pamawas/<service>:latest` by default
- Schema migration runs as a Job before services start
- All services configured for OTel tracing to Tempo
- Prometheus ServiceMonitors require `prometheus-operator` CRDs
- Ingress uses nginx class with cert-manager for TLS
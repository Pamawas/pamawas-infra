#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CHART="$ROOT/helm/pamawas"
RENDERED=$(mktemp)
trap 'rm -f "$RENDERED"' EXIT

for command in helm kubeconform; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'error: required command not found: %s\n' "$command" >&2
    exit 127
  fi
done

helm lint "$CHART"
helm template test-release "$CHART" \
  --namespace pamawas-test \
  --set llm.apiKey=test-key \
  --set external.postgresql.username=test-user \
  --set external.postgresql.password=test-password \
  >"$RENDERED"

kubeconform \
  -strict \
  -summary \
  -kubernetes-version 1.28.0 \
  -skip ServiceMonitor \
  "$RENDERED"

assert_rendered() {
  local pattern=$1
  local description=$2
  if ! grep -Eq "$pattern" "$RENDERED"; then
    printf 'error: rendered chart missing %s\n' "$description" >&2
    exit 1
  fi
}

assert_rendered '^kind: Deployment$' 'deployments'
assert_rendered '^kind: Job$' 'schema migration job'
assert_rendered '^kind: Service$' 'services'
assert_rendered '^kind: Ingress$' 'ingress'
assert_rendered '^  name: test-release-pamawas-investigator$' 'investigator resource'
assert_rendered '^            - name: DATABASE_URL$' 'database configuration'
assert_rendered '^            - name: OTEL_EXPORTER_OTLP_ENDPOINT$' 'OpenTelemetry configuration'
assert_rendered '^                name: test-release-pamawas-secrets$' 'shared secret reference'

printf 'Infrastructure validation passed.\n'

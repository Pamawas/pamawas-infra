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

# Debug: show what kinds are rendered
printf 'Rendered resource kinds:\n' >&2
grep '^kind:' "$RENDERED" | sort | uniq -c >&2

assert_rendered() {
  local pattern=$1
  local description=$2
  if ! grep -Eq "$pattern" "$RENDERED"; then
    printf 'error: rendered chart missing %s\n' "$description" >&2
    printf 'Searching for pattern: %s\n' "$pattern" >&2
    exit 1
  fi
}

# Check for core resources (flexible patterns)
assert_rendered '^kind: Deployment$' 'at least one Deployment'
assert_rendered '^kind: Job$' 'at least one Job (schema migration)'
assert_rendered '^kind: Service$' 'at least one Service'
assert_rendered '^kind: Ingress$' 'at least one Ingress'

# Check for key configuration (more flexible)
assert_rendered 'DATABASE_URL' 'database configuration'
assert_rendered 'OTEL_EXPORTER_OTLP_ENDPOINT' 'OpenTelemetry configuration'

printf 'Infrastructure validation passed.\n'

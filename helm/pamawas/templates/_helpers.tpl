{{/*
Expand the name of the chart.
*/}}
{{- define "pamawas.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "pamawas.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pamawas.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pamawas.labels" -}}
helm.sh/chart: {{ include "pamawas.chart" . }}
{{ include "pamawas.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pamawas.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pamawas.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: pamawas
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "pamawas.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "pamawas.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Deployment labels
*/}}
{{- define "pamawas.deploymentLabels" -}}
{{- include "pamawas.selectorLabels" . | indent 4 }}
{{- end }}

{{/*
Container resource limits/requests
*/}}
{{- define "pamawas.resources" -}}
{{- toYaml . | nindent 12 }}
{{- end }}

{{/*
Probe configuration
*/}}
{{- define "pamawas.probes" -}}
livenessProbe:
  httpGet:
    path: /healthz
    port: {{ .Values.commonConfig.port }}
  initialDelaySeconds: {{ .Values.liveness.initialDelaySeconds }}
  periodSeconds: {{ .Values.liveness.periodSeconds }}
readinessProbe:
  httpGet:
    path: /ready
    port: {{ .Values.commonConfig.port }}
  initialDelaySeconds: {{ .Values.readiness.initialDelaySeconds }}
  periodSeconds: {{ .Values.readiness.periodSeconds }}
{{- end }}
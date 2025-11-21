{{/*
Expand the name of the chart.
*/}}
{{- define "tetragon-observability-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "tetragon-observability-stack.fullname" -}}
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
{{- define "tetragon-observability-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tetragon-observability-stack.labels" -}}
helm.sh/chart: {{ include "tetragon-observability-stack.chart" . }}
{{ include "tetragon-observability-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tetragon-observability-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tetragon-observability-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tetragon-observability-stack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "tetragon-observability-stack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the namespace to use
*/}}
{{- define "tetragon-observability-stack.namespace" -}}
{{- default .Release.Namespace .Values.global.namespace }}
{{- end }}

{{/*
Validate required values
*/}}
{{- define "tetragon-observability-stack.validateValues" -}}
{{- if and .Values.otelAgent.enabled (not .Values.global.otelGatewayEndpoint) }}
    {{- fail "global.otelGatewayEndpoint is required when otelAgent is enabled" }}
{{- end }}
{{- if and (eq .Values.policies.mandateSource "url") (not .Values.policies.mandateUrl) }}
    {{- fail "policies.mandateUrl is required when policies.mandateSource is 'url'" }}
{{- end }}
{{- end }}

{{/*
Tetragon policies ConfigMap name
*/}}
{{- define "tetragon-observability-stack.policiesConfigMapName" -}}
{{- include "tetragon-observability-stack.fullname" . }}-policies
{{- end }}

{{/*
Tetragon mandate ConfigMap name
*/}}
{{- define "tetragon-observability-stack.mandateConfigMapName" -}}
{{- include "tetragon-observability-stack.fullname" . }}-mandate
{{- end }}

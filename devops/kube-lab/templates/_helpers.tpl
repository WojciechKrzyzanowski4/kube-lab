{{- define "kube-lab.name" -}}
{{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{ define "kube-lab.fullname" -}}
{{ $name := default .Chart.Name .Values.nameOverride -}}
{{ printf "%s-%s" $name .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{ define "kube-lab.labels" -}}
app.kubernetes.io/name: {{ include "kube-lab.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
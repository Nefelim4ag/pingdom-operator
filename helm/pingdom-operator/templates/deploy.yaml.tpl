---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ .Release.Name }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ .Release.Namespace }}-{{ .Release.Name }}
rules:
  - verbs:
      - get
      - watch
      - list
    apiGroups:
      - networking.k8s.io
    resources:
      - ingresses
  - verbs:
      - get
      - watch
      - list
    apiGroups:
      - apiextensions.k8s.io
    resources:
      - customresourcedefinitions
  - verbs:
      - get
      - list
      - watch
    apiGroups:
      - ''
    resources:
      - namespaces
  - verbs:
      - get
      - list
      - watch
    apiGroups:
      - 'projectcontour.io'
    resources:
      - httpproxies
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ .Release.Namespace }}-{{ .Release.Name }}
subjects:
- kind: ServiceAccount
  name: {{ .Release.Name }}
  apiGroup: ""
  namespace: {{ .Release.Namespace }}
roleRef:
  kind: ClusterRole
  name: {{ .Release.Namespace }}-{{ .Release.Name }}
  apiGroup: ""
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: {{ .Release.Name }}
spec:
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      serviceAccountName: {{ .Release.Name }}
      serviceAccount: {{ .Release.Name }}
      containers:
        - name: {{ .Release.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          env:
          {{- with .Values.env }}
          {{- range $key, $value := . }}
          - name: {{ $key }}
          {{- if kindIs "string" $value }}
            value: {{ tpl (toYaml $value) $ }}
          {{- else }}
            {{- tpl (toYaml $value) $ | nindent 12 }}
          {{- end }}
          {{- end }}
          {{- end }}
          resources: {{ .Values.resources | toJson }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $.Release.Name }}-integrations
data:
  integrations: |
    {{ .Values.integrations | toJson | indent 4}}

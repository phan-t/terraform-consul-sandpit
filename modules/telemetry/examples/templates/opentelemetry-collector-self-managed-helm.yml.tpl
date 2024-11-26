nameOverride: "${name}"
mode: "daemonset"
presets:
  logsCollection:
    enabled: true
    includeCollectorLogs: true
  hostMetrics:
    enabled: false
  kubernetesAttributes:
    enabled: true
    extractAllPodLabels: true
    extractAllPodAnnotations: true
  kubeletMetrics:
    enabled: false
  kubernetesEvents:
    enabled: false
  clusterMetrics:
    enabled: false
config:
  exporters:
    splunk_hec:
      token: "${hec_token}"
      endpoint: "https://${hec_endpoint}:8088/services/collector"
      source: "otel"
      sourcetype: "otel"
      tls:
        insecure_skip_verify: true
    prometheusremotewrite:
      endpoint: "http://${prometheus_remote_write_endpoint}/api/v1/write"
  processors:
    resourcedetection:
      detectors:
        - system
  receivers:
    jaeger: null
    zipkin: null
    prometheus:
      config:
        global:
          scrape_interval: "60s"
        scrape_configs:
          # - job_name: "self-managed-consul-cluster"
          #   metrics_path: "/v1/agent/metrics"
          #   scheme: "https"
          #   authorization:
          #     credentials: "${consul_token}"
          #   tls_config:
          #     insecure_skip_verify: true
          #   kubernetes_sd_configs:
          #     - role: pod
          #   relabel_configs:
          #     - source_labels: [__meta_kubernetes_pod_label_app]
          #       action: keep
          #       regex: consul
          #     - source_labels: [__meta_kubernetes_pod_label_component]
          #       action: keep
          #       regex: server
          #     - source_labels: [__meta_kubernetes_pod_container_port_number]
          #       action: keep
          #       regex: 8501
          - job_name: "kubernetes-pods"
            scrape_interval: 10s
            kubernetes_sd_configs:
              - role: pod
            relabel_configs:
              - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
                action: keep
                regex: true
              - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_metric_path]
                action: replace
                target_label: __metrics_path__
                regex: (.+)
              - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_scrape_port]
                action: replace
                regex: ([^:]+)(?::\d+)?;(\d+)
                replacement: $1:$2
                target_label: __address__
              - action: labelmap
                regex: __meta_kubernetes_pod_label_(.+)
              - source_labels: [__meta_kubernetes_namespace]
                action: replace
                target_label: namespace
              - source_labels: [__meta_kubernetes_pod_name]
                action: replace
                target_label: pod
  service:
    # telemetry:
    #   logs:
    #     level: DEBUG
    pipelines:
      logs:
        exporters:
          - splunk_hec
        processors:
          - memory_limiter
          - batch
          - resourcedetection
        receivers:
          - otlp
      metrics:
        exporters:
          - prometheusremotewrite
        processors:
          - batch
        receivers:
          - prometheus
      traces: null

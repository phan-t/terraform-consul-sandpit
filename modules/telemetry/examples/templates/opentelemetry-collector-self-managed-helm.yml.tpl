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
          - job_name: "self-managed-consul-cluster"
            metrics_path: "/v1/agent/metrics"
            scheme: "https"
            authorization:
              credentials: "${consul_token}"
            tls_config:
              insecure_skip_verify: true
            kubernetes_sd_configs:
              - role: pod
            relabel_configs:
              - source_labels: [__meta_kubernetes_pod_label_app]
                regex: consul
                action: keep
              - source_labels: [__meta_kubernetes_pod_label_component]
                regex: server
                action: keep
              - source_labels: [__meta_kubernetes_pod_container_port_number]
                regex: 8501
                action: keep
          - job_name: envoy-metrics
            consul_sd_configs:
              - server: "consul.service.consul:8501"
                scheme: "https"
                datacenter: ${consul_datacenter}
                tls_config:
                  insecure_skip_verify: true
            relabel_configs:
              - source_labels:
                  - __meta_consul_service
                action: drop
                regex: (.+)-sidecar-proxy
              - source_labels:
                  - __meta_consul_service_metadata_metrics_port
                action: keep
                regex: (.+)
              - source_labels:
                  - __meta_consul_address
                  - __meta_consul_service_metadata_metrics_port
                regex: (.+);(\d+)
                replacement: ${1}:${2}
                target_label: __address__
  service:
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

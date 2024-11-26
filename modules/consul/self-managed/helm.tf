resource "local_file" "consul-server-helm-values" {
  content = templatefile("${path.root}/templates/self-managed-consul-server-helm.yml", {
    deployment_name       = "${var.deployment_name}-${var.cloud}"
    consul_version        = var.consul_version
    replicas              = var.replicas
    serf_lan_port         = var.serf_lan_port
    cloud                 = var.cloud
    storageclass          = var.storageclass
    prometheus_fqdn       = var.prometheus_fqdn
    })
  filename = "${path.module}/${var.cloud}-server-helm-values.yml.tmp"
}

# consul server
resource "helm_release" "consul-server" {
  name          = "${var.deployment_name}-consul-server"
  chart         = "consul"
  repository    = "https://helm.releases.hashicorp.com"
  version       = var.helm_chart_version
  namespace     = "consul"
  timeout       = "300"
  wait          = true
  values        = [
    local_file.consul-server-helm-values.content
  ]

  depends_on    = [
    kubernetes_namespace.consul,
    kubernetes_secret.consul-ent-license,
  ]
}
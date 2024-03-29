resource "local_file" "eks-splunk-enterprise-helm-values" {
  content = templatefile("${path.root}/modules/telemetry/examples/templates/splunk-enterprise-helm.yml.tpl", {
    })
  filename = "${path.module}/eks-splunk-enterprise-helm-values.yml.tmp"
}

# splunk operator & enterprise
resource "helm_release" "splunk-enterprise" {
  name             = "${var.deployment_name}-splunk-enterprise"
  chart            = "splunk-enterprise"
  repository       = "https://splunk.github.io/splunk-operator"
  version          = var.helm_chart_version
  namespace        = var.namespace
  create_namespace = true
  timeout          = "300"
  wait             = true
  values           = [
    local_file.eks-splunk-enterprise-helm-values.content
  ]
}
output "aws_ui_public_fqdn" {
  description = "UI public ip"
  value       = var.cloud == "aws" ? data.kubernetes_service.consul-ui.status.0.load_balancer.0.ingress.0.hostname : ""
}
output "gcp_ui_public_fqdn" {
  description = "UI public ip"
  value       = var.cloud == "gcp" ? data.kubernetes_service.consul-ui.status.0.load_balancer.0.ingress.0.ip : ""
}

output "bootstrap_token" {
  description = "ACL bootstrap token"
  value       = data.kubernetes_secret.consul-bootstrap-token.data.token
}
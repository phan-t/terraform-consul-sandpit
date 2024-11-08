// generic outputs

output "deployment_id" {
  description = "deployment identifier"
  value       = local.deployment_id
}

output "deployment_name" {
  description = "deployment name to prefix resources"
  value       = var.deployment_name
}

output "consul_version" {
  description = "consul version"
  value       = var.consul_version
}

// amazon web services (aws) outputs

output "aws_region" {
  description = "aws region"
  value       = var.aws_region
}

output "aws_vpc_id" {
  description = "aws vpc id"
  value       = module.infra-aws.vpc_id
}

output "aws_key_pair_name" {
  description = "aws key pair name"
  value       = module.infra-aws.key_pair_name
}

output "aws_bastion_public_fqdn" {
  description = "aws public fqdn of bastion node"
  value       = module.infra-aws.bastion_public_fqdn
}

output "aws_consul_ui_public_fqdn" {
  description = "aws consul datacenter ui public fqdn"
  value       = var.enable_hcp_consul == false ? "https://${module.consul-server-aws[0].aws_ui_public_fqdn}" : null
}

output "aws_consul_bootstrap_token" {
  description = "aws consul acl bootstrap token"
  value       = var.enable_hcp_consul == false ? module.consul-server-aws[0].bootstrap_token : null
  sensitive   = true
}

// google gloud platform (gcp) outputs

output "gcp_region" {
  description = "gcp region"
  value       = var.enable_gcp == true ? var.gcp_region : null
}

output "gcp_project_id" {
  description = "gcp project"
  value       = var.enable_gcp == true ? var.gcp_project_id : null
}

output "gcp_consul_ui_public_fqdn" {
  description = "gcp consul datacenter ui public fqdn"
  value       = var.enable_gcp == true ? "https://${module.consul-server-gcp[0].gcp_ui_public_fqdn}" : null
}

output "gcp_consul_bootstrap_token" {
  description = "gcp consul acl bootstrap token"
  value       = var.enable_gcp == true ? module.consul-server-gcp[0].bootstrap_token : null
  sensitive   = true
}

// hashicorp cloud platform (hcp) outputs

output "hcp_client_id" {
  description = "hcp client id"
  value       = var.hcp_client_id
  sensitive   = true
}

output "hcp_client_secret" {
  description = "hcp client secret"
  value       = var.hcp_client_secret
  sensitive   = true
}

# output "hcp_consul_public_fqdn" {
#   description = "hcp consul public fqdn"
#   value       = var.enable_hcp_consul == true ? module.consul-hcp[0].public_endpoint_url : null
# }

# output "hcp_consul_root_token" {
#   description = "hcp consul root token"
#   value       = var.enable_hcp_consul == true ? module.consul-hcp[0].public_endpoint_url : null
#   sensitive   = true
# }

output "hcp_vault_public_fqdn" {
  description = "HCP vault public fqdn"
  value       = var.enable_hcp_vault == true ? module.vault-hcp[0].public_endpoint_url : null
}

output "hcp_vault_root_token" {
  description = "HCP vault root token"
  value       = var.enable_hcp_vault == true ? module.vault-hcp[0].root_token : null
  sensitive   = true
}

// hashicorp self-managed consul outputs

output "consul_helm_chart_version" {
  description = "Helm chart version"
  value       = var.consul_helm_chart_version
}

// telemetry outputs

output "splunk_public_fqdn" {
  description = "splunk service public fqdn"
  value       = var.enable_telemetry == true ? module.telemetry[0].splunk_public_fqdn : null
}

output "splunk_admin_password" {
  description = "splunk admin password"
  value       = var.enable_telemetry == true ? module.telemetry[0].splunk_admin_password : null
  sensitive   = true
}

output "grafana_public_fqdn" {
  description = "splunk service public fqdn"
  value       = var.enable_telemetry == true ? module.telemetry[0].grafana_public_fqdn : null
}
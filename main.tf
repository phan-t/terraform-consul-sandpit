locals {
  deployment_id = lower("${var.deployment_name}-${random_string.suffix.result}")
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "local_file" "consul-ent-license" {
  content  = var.consul_ent_license
  filename = "${path.root}/consul-ent-license.hclic"
}

// hashicorp cloud platform (hcp) infrastructure

module "hcp-hvn" {
  source = "./modules/infra/hcp"

  region                     = var.aws_region
  deployment_id              = local.deployment_id
  cidr                       = var.hcp_hvn_cidr
  aws_vpc_cidr               = var.aws_vpc_cidr
  aws_tgw_id                 = module.infra-aws.tgw_id
  aws_ram_resource_share_arn = module.infra-aws.ram_resource_share_arn
}

// amazon web services (aws) infrastructure

module "infra-aws" {
  source  = "./modules/infra/aws"
  
  region                      = var.aws_region
  deployment_id               = local.deployment_id
  vpc_cidr                    = var.aws_vpc_cidr
  eks_cluster_version         = var.aws_eks_cluster_version
  eks_worker_instance_type    = var.aws_eks_worker_instance_type
  eks_worker_capacity_type    = var.aws_eks_worker_capacity_type
  eks_worker_desired_capacity = var.aws_eks_worker_desired_capacity
  hcp_hvn_provider_account_id = module.hcp-hvn.provider_account_id
  hcp_hvn_cidr                = var.hcp_hvn_cidr
  consul_serf_lan_port        = var.consul_serf_lan_port
}

// google cloud platform (gcp) infrastructure

module "infra-gcp" {
  source  = "./modules/infra/gcp"

  count = var.enable_gcp ? 1 : 0
  
  region                   = var.gcp_region
  project_id               = var.gcp_project_id
  deployment_id            = local.deployment_id
  private_subnets          = var.gcp_private_subnets
  gke_pod_subnet           = var.gcp_gke_pod_subnet
  gke_cluster_service_cidr = var.gcp_gke_cluster_service_cidr
}

// hcp consul

module "consul-hcp" {
  source = "./modules/consul/hcp"
  providers = {
    consul     = consul.hcp
   }

  count = var.enable_hcp_consul ? 1 : 0

  deployment_name = var.deployment_name
  hvn_id          = module.hcp-hvn.id
  tier            = var.hcp_consul_tier
  min_version     = var.consul_version
}

// hcp vault

module "vault-hcp" {
  source = "./modules/vault/hcp"

  count = var.enable_hcp_vault ? 1 : 0

  deployment_name = var.deployment_name
  hvn_id          = module.hcp-hvn.id
  tier            = var.hcp_vault_tier
}

// consul datacenter in aws

module "consul-server-aws" {
  source = "./modules/consul/self-managed"
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
    consul     = consul.aws
   }

  count = var.enable_hcp_consul ? 0 : 1

  deployment_name       = var.deployment_name
  helm_chart_version    = var.consul_helm_chart_version
  consul_version        = "${var.consul_version}-ent"
  consul_ent_license    = var.consul_ent_license
  serf_lan_port         = var.consul_serf_lan_port
  replicas              = var.consul_replicas
  cloud                 = "aws"
  peering_token         = ""
  storageclass          = "gp3"
  efs_file_system_id    = module.infra-aws.efs_file_system_id

  depends_on = [
    module.infra-aws
  ]
}

// consul datacenter in gcp

module "consul-server-gcp" {
  source = "./modules/consul/self-managed"
  providers = {
    kubernetes = kubernetes.gke
    helm       = helm.gke
    consul     = consul.gcp
   }

  count = var.enable_gcp ? 1 : 0

  deployment_name       = var.deployment_name
  helm_chart_version    = var.consul_helm_chart_version
  consul_version        = "${var.consul_version}-ent"
  consul_ent_license    = var.consul_ent_license
  serf_lan_port         = var.consul_serf_lan_port
  replicas              = var.consul_replicas
  cloud                 = "gcp"
  peering_token         = module.consul-server-aws[0].peering_token
  storageclass          = ""
  efs_file_system_id    = ""

  depends_on = [
    module.infra-gcp,
  ]
}

// consul client (default partition) in aws

module "consul-client-aws" {
  source    = "./modules/consul/hcp-client"
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
   }

  count = var.enable_hcp_consul ? 1 : 0

  deployment_name         = var.deployment_name
  helm_chart_version      = var.consul_helm_chart_version
  consul_version          = "${var.consul_version}-ent"
  private_endpoint_url    = var.enable_hcp_consul == false ? module.consul-hcp[0].private_endpoint_url : ""
  bootstrap_token         = var.enable_hcp_consul == false ? module.consul-hcp[0].bootstrap_token : ""
  gossip_encrypt_key      = var.enable_hcp_consul == false ? module.consul-hcp[0].gossip_encrypt_key : ""
  client_ca_cert          = var.enable_hcp_consul == false ? module.consul-hcp[0].client_ca_cert : ""
  replicas                = var.consul_replicas
  kubernetes_api_endpoint = data.aws_eks_cluster.cluster.endpoint
  cloud                   = "aws"

  depends_on = [
    module.infra-aws
  ]
}

module "telemetry" {
  source    = "./modules/telemetry"
  providers = {
    kubernetes.eks = kubernetes.eks
    kubernetes.gke = kubernetes.gke
    helm.eks       = helm.eks
    helm.gke       = helm.gke
  }

  count = var.enable_telemetry ? 1 : 0

  deployment_name                            = var.deployment_name
  aws_consul_token                           = module.consul-server-aws[0].bootstrap_token
  enable_gcp                                 = var.enable_gcp
  gcp_consul_token                           = var.enable_gcp == true ? module.consul-server-gcp[0].bootstrap_token : ""
  splunk_operator_helm_chart_version         = var.splunk_operator_helm_chart_version
  prometheus_helm_chart_version              = var.prometheus_helm_chart_version
  grafana_helm_chart_version                 = var.grafana_helm_chart_version
  opentelemetry_collector_helm_chart_version = var.opentelemetry_collector_helm_chart_version
}
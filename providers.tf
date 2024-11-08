terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.74.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.43.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.17.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5.0"
    }
    hcp = {
      source = "hashicorp/hcp"
      version = "~> 0.72.0"
    }
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.18.0"
    }
  }
}

provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
}

provider "aws" {
  region = var.aws_region
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

data "aws_eks_cluster" "cluster" {
  name = module.infra-aws.eks_cluster_name
}

provider "kubernetes" {
  alias = "eks"
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    command     = "aws"
  }
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

data "google_client_config" "default" {}

provider "kubernetes" {
  alias = "gke"
  host  = var.enable_gcp == true ? module.infra-gcp[0].cluster_api_endpoint : null
  token = data.google_client_config.default.access_token
  cluster_ca_certificate =var.enable_gcp == true ? base64decode(module.infra-gcp[0].cluster_ca_certificate) : null
}

provider "helm" {
  alias = "gke"
  kubernetes {
    host  = var.enable_gcp == true ? module.infra-gcp[0].cluster_api_endpoint : null
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = var.enable_gcp == true ? base64decode(module.infra-gcp[0].cluster_ca_certificate) : null
  }
}

provider "consul" {
  alias = "hcp"
  address        = module.consul-hcp.public_endpoint_url
  scheme         = "https"
  datacenter     = "${var.deployment_name}-hcp"
  token          = module.consul-hcp.root_token
}

provider "consul" {
  alias = "aws"
  address        = "https://${module.consul-server-aws[0].aws_ui_public_fqdn}"
  scheme         = "https"
  datacenter     = "${var.deployment_name}-aws"
  token          = module.consul-server-aws[0].bootstrap_token
  insecure_https = true
}

provider "consul" {
  alias = "gcp"
  address        = "https://${module.consul-server-gcp[0].gcp_ui_public_fqdn}"
  scheme         = "https"
  datacenter     = "${var.deployment_name}-gcp"
  token          = module.consul-server-gcp[0].bootstrap_token
  insecure_https = true
}
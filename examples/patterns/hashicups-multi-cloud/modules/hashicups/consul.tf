// create kubernetes resources on hashicups eks cluster

resource "kubernetes_namespace" "eks-hashicups-namespaces" {
  provider = kubernetes.eks-hashicups

  for_each = toset(var.hashicups_config.aws.eks_namespaces)

  metadata {
    name = each.key
  }
}

resource "kubernetes_namespace" "gke-hashicups-namespaces" {
  provider = kubernetes.gke-hashicups

  for_each = toset(var.hashicups_config.gcp.gke_namespaces)

  metadata {
    name = each.key
  }
}

// create admin partition on aws consul server

resource "consul_admin_partition" "eks-hashicups" {
  provider = consul.aws

  name        = "hashicups"
  description = "Partition for hashicups team"
}

// create admin partition on gcp consul server

resource "consul_admin_partition" "gke-hashicups" {
  provider = consul.gcp

  name        = "hashicups"
  description = "Partition for hashicups team"
}

// create hashicups partition cluster peering token for aws and gcp

resource "consul_peering_token" "aws-gcp-hashicups" {
  provider = consul.aws

  peer_name = "aws-gcp-hashicups"
  partition = consul_admin_partition.eks-hashicups.name
}

// create hashicups partition cluster peering connection between aws and gcp

resource "consul_peering" "aws-gcp-hashicups" {
  provider = consul.gcp

  peer_name     = "aws-gcp-hashicups"
  peering_token = consul_peering_token.aws-gcp-hashicups.peering_token
  partition     = consul_admin_partition.gke-hashicups.name
}

resource "consul_config_entry" "eks-proxy_defaults" {
  provider = consul.aws

  kind        = "proxy-defaults"
  name        = "global"
  partition   = consul_admin_partition.eks-hashicups.name

  config_json = jsonencode({
    Config = {
      Protocol = "http"
    }
  })
}

resource "consul_config_entry" "gke-proxy_defaults" {
  provider = consul.gcp

  kind        = "proxy-defaults"
  name        = "global"
  partition   = consul_admin_partition.gke-hashicups.name

  config_json = jsonencode({
    Config = {
      Protocol = "http"
    }
  })
}

// create api-gateway resources

resource "kubernetes_manifest" "eks-hashicups-api-gw-listener" {
  provider = kubernetes.eks-hashicups

  manifest = yamldecode(file("${path.root}/templates/api-gw-http-listener.yml"))
}

resource "kubernetes_manifest" "eks-hashicups-api-gw-http-route" {
  provider = kubernetes.eks-hashicups

  manifest = yamldecode(file("${path.root}/templates/api-gw-http-route.yml"))
}

resource "time_sleep" "wait_5_seconds" {
  create_duration = "5s"

  depends_on = [
    kubernetes_deployment.nginx,
    kubernetes_deployment.frontend,
    kubernetes_deployment.public-api,
    kubernetes_deployment.product-api,
    kubernetes_deployment.product-api-db,
    kubernetes_deployment.payments-api
  ]
}
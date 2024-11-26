// retrieve consul server data

data "kubernetes_service" "eks-consul-partition-service-fqdn" {
  provider = kubernetes.eks

  metadata {
    name = "consul-expose-servers"
    namespace = "consul"
  }
}

data "kubernetes_secret" "eks-consul-ca-cert" {
  provider = kubernetes.eks

  metadata {
    name = "consul-ca-cert"
    namespace = "consul"
  }
}

data "kubernetes_secret" "eks-consul-ca-key" {
  provider = kubernetes.eks

  metadata {
    name = "consul-ca-key"
    namespace = "consul"
  }
}

data "kubernetes_secret" "eks-consul-bootstrap-token" {
  provider = kubernetes.eks

  metadata {
    name = "consul-bootstrap-acl-token"
    namespace = "consul"
  }
}

// create kubernetes resources on hashicups eks cluster

resource "kubernetes_namespace" "eks-consul" {
  provider = kubernetes.eks-hashicups

  metadata {
    name = "consul"
  }
}

resource "kubernetes_secret" "eks-consul-bootstrap-token" {
  provider = kubernetes.eks-hashicups

  metadata {
    name      = "${var.deployment_name}-aws-bootstrap-token"
    namespace = "consul"
  }

  data = {
    token = data.kubernetes_secret.eks-consul-bootstrap-token.data.token
  }

  depends_on = [ 
    kubernetes_namespace.eks-consul 
  ]
}

resource "kubernetes_secret" "eks-consul-client-secrets" {
  provider = kubernetes.eks-hashicups

  metadata {
    name      = "${var.deployment_name}-aws-client-secrets"
    namespace = "consul"
  }

  data = {
    gossipEncryptionKey = ""
    caCert              = data.kubernetes_secret.eks-consul-ca-cert.data["tls.crt"]
    caKey               = data.kubernetes_secret.eks-consul-ca-key.data["tls.key"]
  }

  depends_on = [ 
    kubernetes_namespace.eks-consul 
  ]
}

// create and deploy consul hashicups partition helm

resource "local_file" "eks-client-hashicups-partition-helm-values" {
  content = templatefile("${path.root}/templates/self-managed-consul-client-partition-helm.yml", {
    partition_name                = "hashicups"
    deployment_name               = "${var.deployment_name}-aws"
    consul_version                = var.min_version
    external_server_private_fqdn  = data.kubernetes_service.eks-consul-partition-service-fqdn.status.0.load_balancer.0.ingress.0.hostname
    external_server_https_port    = 8501
    kubernetes_api_endpoint       = var.eks_kubernetes_api_endpoint
    replicas                      = var.replicas
    cloud                         = "aws"
    })
  filename = "${path.module}/configs/eks-client-hashicups-partition-helm-values.yml.tmp"
}


resource "helm_release" "eks-consul-client-hashicups" {
  provider = helm.eks-hashicups

  name          = "${var.deployment_name}-consul-client"
  chart         = "consul"
  repository    = "https://helm.releases.hashicorp.com"
  version       = var.helm_chart_version
  namespace     = "consul"
  timeout       = "300"
  wait          = true
  values        = [
    local_file.eks-client-hashicups-partition-helm-values.content
  ]

  depends_on    = [
    kubernetes_namespace.eks-consul
  ]
}

// deploy opentelemetry collector on hashicups eks cluster

resource "helm_release" "eks-opentelemetry-self-managed-hashicups" {
  provider = helm.eks-hashicups

  count = var.enable_telemetry ? 1 : 0

  name             = "${var.deployment_name}-opentelemetry-collector"
  chart            = "opentelemetry-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  version          = var.opentelemetry_collector_helm_chart_version
  namespace        = "telemetry"
  create_namespace = true
  timeout          = "300"
  wait             = true
  values           = [ file("../../../modules/telemetry/opentelemetry/configs/eks-opentelemetry-collector-self-managed-helm-values.yml.tmp")]
}
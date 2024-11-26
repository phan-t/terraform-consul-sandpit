terraform {
  required_providers {
    aws = {
    }
    kubernetes = {
      configuration_aliases = [ kubernetes.eks, kubernetes.gke]
    }
    helm = {
      configuration_aliases = [ helm.eks, helm.gke ]
    }
  }
}
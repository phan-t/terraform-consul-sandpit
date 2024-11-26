variable "deployment_name" {
  description = "deployment name to prefix resources"
  type        = string
}

variable "route53_zone_name" {
  description = "aws route53 zone name"
  type        = string
}

variable "namespace" {
  description = "kubernetes namespace"
  type        = string
}

variable "helm_chart_version" {
  description = "helm chart version"
  type        = string
}
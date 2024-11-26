variable "deployment_name" {
  description = "Deployment name, used to prefix resources"
  type        = string
}

variable "cloud" {
  description = "cloud provider"
  type        = string
}

variable "helm_chart_version" {
  type        = string
  description = "Helm chart version"
}

variable "consul_version" {
  description = "Consul version"
  type        = string
}

variable "consul_ent_license" {
  description = "Consul enterprise license"
  type        = string
}

variable "serf_lan_port" {
  description = "Serf lan port"
  type        = number
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
}

variable "peering_token" {
  description = "consul default partition peering token"
  type        = string
}

variable "storageclass" {
  description = "kubernetes storage class"
  type        = string
}

variable "efs_file_system_id" {
  description = "aws efs file system id"
  type        = string
}

variable "prometheus_fqdn" {
  description = "prometheus fqdn"
  type        = string
}
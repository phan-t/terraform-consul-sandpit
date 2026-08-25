data "terraform_remote_state" "tcm" {
  backend = "local"

  config = {
    path = "../../../terraform.tfstate"
  }
}

data "google_compute_network" "vpc" {
  name   = data.terraform_remote_state.tcm.outputs.deployment_id
}

data "google_compute_subnetwork" "private" {
  name   = "private"
}

module "dc1-aws-micro-service-a" {
  source = "./modules/fake-service-k8s"
  providers = {
    kubernetes = kubernetes.eks
  }

  service_name = "dc1-aws-micro-service-a"
  upstreams = "dc1-aws-micro-service-b:9090"
}

module "dc1-aws-micro-service-b" {
  source = "./modules/fake-service-k8s"
  providers = {
    kubernetes = kubernetes.eks
  }

  service_name = "dc1-aws-micro-service-b"
  upstreams = "dc1-aws-micro-service-c:9090, dc1-aws-vm-service-d:9090"
}

module "dc1-aws-micro-service-c" {
  source = "./modules/fake-service-k8s"
  providers = {
    kubernetes = kubernetes.eks
  }

  service_name = "dc1-aws-micro-service-c"
  upstreams = ""
}

module "dc1-aws-vm-service-d" {
  source = "./modules/fake-service-k8s"
  providers = {
    kubernetes = kubernetes.eks
  }

  service_name = "dc1-aws-vm-service-d"
  upstreams = ""
}

module "dc2-gcp-micro-service-c" {
  source = "./modules/fake-service-k8s"
  providers = {
    kubernetes = kubernetes.gke
  }

  service_name = "dc2-gcp-micro-service-c"
  upstreams = ""
}

resource "consul_config_entry" "ep-dc2-gcp-micro-service-c" {
  provider = consul.gcp
  
  name = "default"
  kind = "exported-services"
  partition   = "default"

  config_json = jsonencode({
    Services = [
      {
        Name = "dc2-gcp-micro-service-c"
        Namespace = "default"
        Consumers = [
          {
            Peer = "aws-gcp-default"
          }
        ]
      }
    ]
  })
}

resource "consul_config_entry" "si-dc2-gcp-micro-service-c" {
  provider = consul.gcp

  name        = "dc2-gcp-micro-service-c"
  kind        = "service-intentions"
  partition   = "default"
  namespace   = "default"

  config_json = jsonencode({
    Sources = [
      {
        Namespace  = "default"
        Action     = "allow"
        Name       = "dc1-aws-micro-service-b"
        Type       = "consul"
        Peer       = "aws-gcp-default"
      }
    ]
  })
}
module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "~> 20.0"

  cluster_name                    = "${var.deployment_id}-hashicups"
  cluster_version                 = var.eks_cluster_version
  vpc_id                          = var.vpc_id
  subnet_ids                      = "${data.aws_subnets.private.ids}"

  cluster_endpoint_public_access  = true
  enable_cluster_creator_admin_permissions = true

  cluster_security_group_additional_rules = {
    // allow consul to communicate with the cluster api.
    ingress_cluster_api_tcp = {
      description                = "vpc-cluster-api-https-tcp"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      cidr_blocks                = [data.aws_vpc.this.cidr_block]
    }
  }
  
  eks_managed_node_group_defaults = { 
  }

  eks_managed_node_groups = {
    "default_node_group" = {
      min_size               = 1
      max_size               = 5
      desired_size           = var.eks_worker_desired_capacity

      instance_types         = ["${var.eks_worker_instance_type}"]
      capacity_type          = var.eks_worker_capacity_type
      key_name               = var.key_pair_key_name
      vpc_security_group_ids = data.aws_security_groups.consul.ids
    }
  }
}

resource "null_resource" "kubeconfig" {

  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
  }

  depends_on = [
    module.eks
  ]
}
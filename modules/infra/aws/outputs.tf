output "vpc_id" {
  description = "VPC id"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet ids"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet ids"
  value       = module.vpc.private_subnets
}

output "key_pair_name" {
  description = "Key pair name"
  value       = module.key_pair.key_pair_name
}   

output "security_group_ssh_id" {
  description = "Security group ssh id"
  value       = module.sg-ssh.security_group_id
}

output "security_group_consul_id" {
  description = "Security group consul id"
  value       = module.sg-consul.security_group_id
}

output "tgw_id"{
  value = module.tgw.ec2_transit_gateway_id
}

output "ram_resource_share_arn" {
  value = module.tgw.ram_resource_share_id
}

output "bastion_public_fqdn" {
  description = "Public fqdn of bastion"
  value       = aws_instance.bastion.public_dns
}

output "eks_cluster_name" {
  description = "EKS cluster id"
  value       = module.eks.cluster_name
}

output "efs_file_system_id" {
  description = "EFS file system id"
  value       = aws_efs_file_system.eks-efs.id
}
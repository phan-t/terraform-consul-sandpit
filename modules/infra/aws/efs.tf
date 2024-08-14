resource "aws_efs_file_system" "eks-efs" {
  creation_token = "eks-efs"
  encrypted      = true  
  
  tags = {
    Name = var.deployment_id
  }
}

resource "aws_efs_mount_target" "efs_mt_0" {
  file_system_id  = aws_efs_file_system.eks-efs.id
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = [module.sg-efs.security_group_id]
}

resource "aws_efs_mount_target" "efs_mt_1" {
  file_system_id  = aws_efs_file_system.eks-efs.id
  subnet_id       = module.vpc.private_subnets[1]
  security_groups = [module.sg-efs.security_group_id]
}

resource "aws_efs_mount_target" "efs_mt_2" {
  file_system_id  = aws_efs_file_system.eks-efs.id
  subnet_id       = module.vpc.private_subnets[2]
  security_groups = [module.sg-efs.security_group_id]
}
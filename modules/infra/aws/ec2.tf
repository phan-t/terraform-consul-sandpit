data "aws_ami" "hc-base-ubuntu-2404" {
  for_each = toset(["amd64", "arm64"])

  filter {
    name   = "name"
    values = [format("hc-base-ubuntu-2404-%s-*", each.value)]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
  most_recent = true
  owners      = ["888995627335"] # ami-prod account
}

resource "aws_instance" "bastion" {
  ami             = data.aws_ami.hc-base-ubuntu-2404["amd64"].id
  instance_type   = "t2.micro"
  key_name        = module.key_pair.key_pair_name
  subnet_id       = element(module.vpc.public_subnets, 1)
  security_groups = [module.sg-ssh.security_group_id]
  
  lifecycle {
    ignore_changes = all
  }

  connection {
    host          = aws_instance.bastion.public_dns
    user          = "ubuntu"
    agent         = false
    private_key   = module.key_pair.private_key_pem
  }

  provisioner "file" {
    source      = "${path.root}/${module.key_pair.key_pair_name}.pem"
    destination = "/home/ubuntu/${module.key_pair.key_pair_name}.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/ubuntu/${module.key_pair.key_pair_name}.pem"
    ]
  }
}
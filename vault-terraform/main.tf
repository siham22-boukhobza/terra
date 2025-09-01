provider "aws" {
  region = var.region_value

}
data "aws_vpc" "default" {
  default = true
}
resource "aws_security_group" "sg" {
  name        = "security group"
  description = "security group"
  vpc_id      = data.aws_vpc.default.id

}
resource "aws_vpc_security_group_ingress_rule" "inbond" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22

}
resource "aws_vpc_security_group_ingress_rule" "inbond1" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8200
  ip_protocol       = "tcp"
  to_port           = 8200

}
resource "aws_vpc_security_group_egress_rule" "sg_out" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
//create key pair for sshing to the ec2


# 1. Generate the RSA key pair
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Upload the public key to AWS as an EC2 key pair
resource "aws_key_pair" "public_key" {
  key_name   = "web" # AWS EC2 key name
  public_key = tls_private_key.my_key.public_key_openssh
}

# 3. Save the private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.my_key.private_key_pem
  filename        = "/workspaces/terra/vault-terraform/web.pem" # Local file path
  file_permission = "0600"
}

resource "aws_instance" "vault" {
  ami                    = var.ami_value
  instance_type          = var.instance_type_value
  vpc_security_group_ids = [aws_security_group.sg.id]
  tags = {
    Name = "vault"
  }
  key_name = aws_key_pair.public_key.key_name

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local_file.private_key.filename)
    host        = self.public_ip
  }


 provisioner "remote-exec" {
  inline = [
    "sudo apt update && sudo apt install -y snapd",
    "sudo snap install vault --classic",
    "vault --version"
  ]
}

}

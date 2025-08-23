provider "aws" {
  region = "us-east-1"

}
//create custom vpc
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "custom vpc"
  }

}
//create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "my internet gateway"
  }
}

//create subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public subnet"
  }

}
//create route table
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "RT internet"
  }
}
//create route table assocision
resource "aws_route_table_association" "RTA" {
  route_table_id = aws_route_table.RT.id
  subnet_id      = aws_subnet.public_subnet.id
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
  filename        = "/workspaces/terra/day4-provisioner/my-temp-key.pem" # Local file path
  file_permission = "0600"
}
//create security group

resource "aws_security_group" "SG" {
  name        = "SG for the ec2"
  description = "this SG allows ssh and HTTP"
  vpc_id      = aws_vpc.myvpc.id

}
resource "aws_vpc_security_group_ingress_rule" "SG_inbond" {
  security_group_id = aws_security_group.SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "SG_inbond1" {
  security_group_id = aws_security_group.SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_egress_rule" "sg_out" {
  security_group_id = aws_security_group.SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

//create EC2

resource "aws_instance" "server" {
  ami                    = "ami-020cba7c55df1f615"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.SG.id]
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.public_key.key_name

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local_file.private_key.filename)
    host        = self.public_ip
  }




  provisioner "file" {

    source      = "/workspaces/terra/day4-provisioner/app.py"
    destination = "/home/ubuntu/app.py"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y python3", # ensure Python is available
      "python3 /home/ubuntu/app.py"
    ]
  }
}

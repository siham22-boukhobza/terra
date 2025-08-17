//create vpc

resource "aws_vpc" "myvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "costum-vpc"
  }
}

variable "av-zone" {
  type        = list(string)
  description = "availibility zone"
  default     = ["us-east-1a", "us-east-1b"]

}
//create public subnets
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.myvpc.id
  count             = length(var.av-zone)
  availability_zone = element(var.av-zone, count.index)
  cidr_block        = cidrsubnet(aws_vpc.myvpc.cidr_block, 8, count.index)
  tags = {
    Name = "public-subet${count.index + 1}"
  }
}
//create private subnets
resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.myvpc.id
  count             = length(var.av-zone)
  availability_zone = element(var.av-zone, count.index + 1)
  cidr_block        = cidrsubnet(aws_vpc.myvpc.cidr_block, 8, count.index + 3)
  tags = {
    Name = "private-subet${count.index + 1}"
  }
}
//create internet gatway
resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "internet gw"
  }

}
//create route table or public subnets
resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id

  }
  tags = {
    Name = "route table"
  }


}

//create route table association

resource "aws_route_table_association" "rta-public" {
  route_table_id = aws_route_table.rt-public.id
  count          = length(var.av-zone)
  subnet_id      = element(aws_subnet.public-subnet[*].id, count.index)

}

//create eip
resource "aws_eip" "eip-for-nat" {

  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet-gw]
}
//create nat gatway
resource "aws_nat_gateway" "ngw" {
  subnet_id = element(aws_subnet.public-subnet[*].id, 0)

  allocation_id = aws_eip.eip-for-nat.id
  depends_on    = [aws_internet_gateway.internet-gw]
  tags = {
    Name = "nat gatway"
  }

}
//create route table for private subnets

resource "aws_route_table" "rt-private" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id

  }
  depends_on = [aws_nat_gateway.ngw]
  tags = {
    Name = "route table or private subnet"
  }
}
//create route table association for private subnet

resource "aws_route_table_association" "rta-private" {
  route_table_id = aws_route_table.rt-private.id
  count          = length(var.av-zone)
  subnet_id      = element(aws_subnet.private-subnet[*].id, count.index)
}

//create security groupe for load balancer
resource "aws_security_group" "sg-alb" {
  name        = "sgroup-for-alb"
  description = "security group for the application load balancer"
  vpc_id      = aws_vpc.myvpc.id
  tags = {
    Name = "sg for load balancer"
  }

}

resource "aws_vpc_security_group_ingress_rule" "inbound-alb" {
  security_group_id = aws_security_group.sg-alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "outbond-alb" {
  security_group_id = aws_security_group.sg-alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
//create security group for servers
resource "aws_security_group" "sg-servers" {
  name        = "sgroup-for-servers"
  description = "security group for the servers within private subnets"
  vpc_id      = aws_vpc.myvpc.id
  tags = {
    Name = "sg for servers"
  }

}

resource "aws_vpc_security_group_ingress_rule" "inbound-servers" {
  security_group_id            = aws_security_group.sg-servers.id
  referenced_security_group_id = aws_security_group.sg-alb.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "outbond-servers" {
  security_group_id = aws_security_group.sg-servers.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
//create application load balancer 
resource "aws_lb" "alb" {
  name               = "applicationlb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg-alb.id]
  subnets            = aws_subnet.public-subnet[*].id
  depends_on         = [aws_internet_gateway.internet-gw]

}
//create target groupe for the load balancer

resource "aws_lb_target_group" "alb-tg" {
  name       = "alb-tg"
  protocol   = "HTTP"
  port       = 80
  vpc_id     = aws_vpc.myvpc.id
  depends_on = [aws_lb.alb]
  tags = {
    Name = "alb-tg"
  }
  health_check {
    path     = "/health" # adjust as needed
    port     = "80"
    protocol = "HTTP"
    matcher  = "200"
  }

}
//create listeer for tg
resource "aws_lb_listener" "alb-ls" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
  tags = {
    Name = "alb-ls"
  }

}

//create servers launch template
resource "aws_launch_template" "server-lt" {
  name          = "slt"
  description   = "lanch template for the auto scailling group"
  image_id      = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  network_interfaces {
    associate_carrier_ip_address = false
    security_groups              = [aws_security_group.sg-servers.id]
  }

  user_data = filebase64("userdata.sh")
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "server-ltemplate"
    }
  }
}
//create autosciling groupe for lanch template
resource "aws_autoscaling_group" "servers-asg" {
  name                = "servers-asg"
  max_size            = 4
  min_size            = 2
  desired_capacity    = 2
  target_group_arns   = [aws_lb_target_group.alb-tg.arn]
  vpc_zone_identifier = aws_subnet.private-subnet[*].id

  launch_template {
    id      = aws_launch_template.server-lt.id
    version = "$Latest"

  }
  health_check_type = "EC2"

}
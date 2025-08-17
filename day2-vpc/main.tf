resource "aws_vpc" "project" {
  cidr_block = var.cidr



}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.project.id
  cidr_block              = var.cidr_sub1
  availability_zone       = var.availability_zone_sub1
  map_public_ip_on_launch = true

}
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.project.id
  cidr_block              = var.cidr_sub2
  availability_zone       = var.availability_zone_sub2
  map_public_ip_on_launch = true

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.project.id

}
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.project.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }



}
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rtb.id


}
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rtb.id


}

resource "aws_security_group" "sg" {
  name        = "sg using terraform"
  description = "security groupe using terraform"
  vpc_id      = aws_vpc.project.id

  tags = {
    Name = "sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_http" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "sg_ssh" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"

  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}
resource "aws_vpc_security_group_ingress_rule" "sg_https" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"

  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}


resource "aws_vpc_security_group_egress_rule" "sg_out" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_instance" "server1" {
  ami           = var.ami_value
  instance_type = var.type_value
  key_name      = "racha"

  subnet_id              = aws_subnet.sub2.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = file("userdata1.sh")


}
resource "aws_instance" "server2" {
  ami                    = var.ami_value
  instance_type          = var.type_value
  subnet_id              = aws_subnet.sub2.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = "racha"
  user_data              = file("userdata2.sh")


}
resource "aws_lb" "alb" {
  name               = "tf-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
  tags = {
    name = "alb"
  }


}


resource "aws_lb_target_group" "lb-tg" {
  name     = "tf-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project.id


  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
resource "aws_lb_target_group_attachment" "attsch1" {
  target_group_arn = aws_lb_target_group.lb-tg.arn
  target_id        = aws_instance.server1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attsch2" {
  target_group_arn = aws_lb_target_group.lb-tg.arn
  target_id        = aws_instance.server2.id
  port             = 80
}

resource "aws_lb_listener" "listener-alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-tg.arn
  }

}




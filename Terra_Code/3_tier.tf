resource "aws_vpc" "one" {
  cidr_block            = var.cidr_block
  instance_tenancy      = "default"
  enable_dns_hostnames  = var.host_name

  tags = {
    Name = "MAIN-VPC"
  }
}
# public subnet 1
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "pub-sub-one"
  }
}
# public subnet 2
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "pub-sub-two"
  }
}

# IG
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.one.id

  tags = {
    Name = "Gateway"
  }
}


# Route table
resource "aws_route_table" "route1" {
  vpc_id                  = aws_vpc.one.id

  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "route-table-one"
  }
}
# Association 
resource "aws_route_table_association" "a" {
  subnet_id                = aws_subnet.sub1.id
  route_table_id           = aws_route_table.route1.id
}

# Route table two
resource "aws_route_table" "route2" {
  vpc_id                  = aws_vpc.one.id

  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "route-table-two"
  }
}
# Association 
resource "aws_route_table_association" "b" {
  subnet_id                = aws_subnet.sub2.id
  route_table_id           = aws_route_table.route2.id
}

# EIP
resource "aws_eip" "eip" {
  #instance = aws_instance.web.id
  domain   = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.sub3.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  }
# private subnet 1
resource "aws_subnet" "sub3" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "pri-sub-one"
  }
}

# private subnet 2
resource "aws_subnet" "sub4" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "pri-sub-two"
  }
}

# Private Route table three
resource "aws_route_table" "route3" {
  vpc_id                  = aws_vpc.one.id

  route {
    cidr_block            = "0.0.0.0/0"
    nat_gateway_id            = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "route-table-three"
  }
}
# Association 
resource "aws_route_table_association" "c" {
  subnet_id                = aws_subnet.sub3.id
  route_table_id           = aws_route_table.route3.id
}

# Private Route table four
resource "aws_route_table" "route4" {
  vpc_id                  = aws_vpc.one.id

  route {
    cidr_block            = "0.0.0.0/0"
    nat_gateway_id            = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "route-table-four"
  }
}
# Association 
resource "aws_route_table_association" "d" {
  subnet_id                = aws_subnet.sub4.id
  route_table_id           = aws_route_table.route4.id
}


# security group
resource "aws_security_group" "security" {
  name                      = "public-sg"
  description               = "Allow web and ssh traffic"
  vpc_id                    = aws_vpc.one.id

  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}


# Create a new load balancer
resource "aws_lb" "mani" {
  name               = "Application-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security.id]
  
  subnet_mapping {
    subnet_id = aws_subnet.sub1.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.sub2.id
  }
  #
  tags = {
    Environment = "App-LB-pub"
  }
}
# load balancer

 resource "aws_lb_target_group" "test" {
  name     = "padayappa"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.one.id
}

resource "aws_lb_listener" "sh_front" {
  load_balancer_arn = aws_lb.mani.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}


# auto scalling template
resource "aws_launch_template" "foobar" {
  name_prefix   = "Temp-auto"
  image_id      = "ami-0dee22c13ea7a9a67"
  instance_type = "t2.micro"
  #security_groups = [aws_security_group.kiran.id]

}
resource "aws_autoscaling_group" "Hukkum" {
  #availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  health_check_type  = "EC2"
  vpc_zone_identifier = [aws_subnet.sub1.id, aws_subnet.sub2.id]
  # attach a lb target group
  target_group_arns = [aws_lb_target_group.test.arn]

  launch_template {
    id      = aws_launch_template.foobar.id
    version = "$Latest"
  }
  #load_balancers = [aws_lb.mani.id]

}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.Hukkum.id
  lb_target_group_arn    = aws_lb_target_group.test.arn
}
resource "aws_autoscaling_policy" "scale_down" {

  name                   = "test_scale_down"
  autoscaling_group_name = aws_autoscaling_group.Hukkum.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 120

}

### Load balancer for private subnet
# Create a new load balancer
resource "aws_lb" "pri-lb" {
  name               = "Application-2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security.id]
  
  subnet_mapping {
    subnet_id = aws_subnet.sub3.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.sub4.id
  }
  #
  tags = {
    Environment = "PRI-LB"
  }
}
# load balancer

 resource "aws_lb_target_group" "test2" {
  name     = "padayappa"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.one.id
}

resource "aws_lb_listener" "sh_front2" {
  load_balancer_arn = aws_lb.pri-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test2.arn
  }
}


# auto scalling template
resource "aws_launch_template" "foobar2" {
  name_prefix   = "Auto-pri"
  image_id      = "ami-0dee22c13ea7a9a67"
  instance_type = "t2.micro"
  #security_groups = [aws_security_group.security.id]

}
resource "aws_autoscaling_group" "tiger" {
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  health_check_type  = "EC2"
  vpc_zone_identifier = [aws_subnet.sub3.id, aws_subnet.sub4.id]
  # attach a lb target group
  target_group_arns = [aws_lb_target_group.test2.arn]

  launch_template {
    id      = aws_launch_template.foobar2.id
    version = "$Latest"
  }
  #load_balancers = [aws_lb.mani.id]

}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "example2" {
  autoscaling_group_name = aws_autoscaling_group.tiger.id
  lb_target_group_arn    = aws_lb_target_group.test2.arn
}
resource "aws_autoscaling_policy" "scale_down2" {

  name                   = "test_scale_down"
  autoscaling_group_name = aws_autoscaling_group.Hukkum.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 120

}




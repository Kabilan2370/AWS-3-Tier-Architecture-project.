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
  availability_zone       = "us-east-1d"

  tags = {
    Name = "pub-sub-one"
  }
}
# public subnet 2
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1e"

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
  availability_zone       = "us-east-1f"

  tags = {
    Name = "pri-sub-one"
  }
}

# private subnet 2
resource "aws_subnet" "sub4" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1g"

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
resource "aws_security_group" "public_sg" {
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

# # Instance profile
# resource "aws_iam_instance_profile" "test_profile" {
#   name = "test_profile"
#   role = aws_iam_role.role.name
# }

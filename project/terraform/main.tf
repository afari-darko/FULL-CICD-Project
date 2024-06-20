provider "aws" {
  # access_key and access_secret_key exported
  region = "eu-west-2"
}

# Create VPC
resource "aws_vpc" "devops-project-vpc" {
  cidr_block = "10.1.0.0/16"
  tags       = { Name = "devops-project-vpc" }
}

# create VPC subnet 1
resource "aws_subnet" "devops-project-pub-sub-01" {
  vpc_id                  = aws_vpc.devops-project-vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-west-2a"
  tags                    = { Name = "devops-project-pub-sub-01" }
}

# create VPC subnet 2
resource "aws_subnet" "devops-project-pub-sub-02" {
  vpc_id                  = aws_vpc.devops-project-vpc.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-west-2a"
  tags                    = { Name = "devops-project-pub-sub-02" }
}

# create internet gateway
resource "aws_internet_gateway" "devops-project-IGW" {
  vpc_id = aws_vpc.devops-project-vpc.id
  tags   = { Name = "devops-project-IGW" }
}

# create routing table
resource "aws_route_table" "devops-project-public-RT" {
  vpc_id = aws_vpc.devops-project-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops-project-IGW.id
  }
}

# Associate routing table to subnet1
resource "aws_route_table_association" "devops-project-RTA-pub-sub-01" {
  subnet_id      = aws_subnet.devops-project-pub-sub-01.id
  route_table_id = aws_route_table.devops-project-public-RT.id
}

# Associate routing table to subnet2
resource "aws_route_table_association" "devops-project-RTA-pub-sub-02" {
  subnet_id      = aws_subnet.devops-project-pub-sub-02.id
  route_table_id = aws_route_table.devops-project-public-RT.id
}

# Security group
resource "aws_security_group" "devops-project-sg" {
  name        = "devops-project-sg"
  description = "SSH Access for devops assets"
  vpc_id      = aws_vpc.devops-project-vpc.id

  ingress {
    // ssh
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    // jenkins
    description = "jenkins port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# EC2 instances
resource "aws_instance" "devops-project-server" {
  ami                    = "ami-035cecbff25e0d91e"
  instance_type          = "t2.large"
  key_name               = "devops"
  vpc_security_group_ids = [aws_security_group.devops-project-sg.id]
  subnet_id              = aws_subnet.devops-project-pub-sub-01.id
  for_each               = toset(["jenkins-master", "jenkins-slave", "ansible-server", sonarqube-server])
  tags                   = { Name = "${each.key}" }
}



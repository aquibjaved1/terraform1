provider "aws" {
  region = "us-east-1"
}

### Creating VPC
resource "aws_vpc" "vpcnew" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  
  tags = {
    Name = "vpcnew"
  }
}

#### Creating Internet Gateway
resource "aws_internet_gateway" "igwnew" {
  vpc_id = aws_vpc.vpcnew.id
  tags = {
    Name = "newig"
  }
}

### Creating Route table
resource "aws_route_table" "newroutetable" {
  vpc_id = aws_vpc.vpcnew.id 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igwnew.id
  }

  tags = {
    Name = "vpcnew_routetable"
  }
}

### Creating subnet
resource "aws_subnet" "publicsubnet" {
  vpc_id = aws_vpc.vpcnew.id
  cidr_block = "10.0.0.0/28"

  tags = {
    Name = "publicsubnetnew"
  }
}

resource "aws_subnet" "pvtsubnet" {
  vpc_id = aws_vpc.vpcnew.id
  cidr_block = "10.0.0.16/28"

  tags = {
    Name = "pvtsubnetnew"
  }
}

#### Associating route table

resource "aws_route_table_association" "rtassociation" {
  subnet_id = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.newroutetable.id
}

### Creating Security Group
resource "aws_security_group" "vpcnewsg" {
  vpc_id = aws_vpc.vpcnew.id
  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Web SG"
  }
}

### Creating EC2 Instance
resource "aws_instance" "ec2server" {
  ami                         = "ami-04b70fa74e45c3917"
  instance_type               = "t2.micro"
  key_name                    = "challenge"
  vpc_security_group_ids      = [aws_security_group.vpcnewsg.id]
  subnet_id                   = aws_subnet.publicsubnet.id
  associate_public_ip_address = true
  user_data                   =<<-EOF
                  #!/bin/bash
                  apt update -y
                  apt install -y apache2
                  systemctl start apache2
                  systemctl enable apache2
                  EOF 
  tags = {
  Name = "ubuntu-server"
  }
}
output "public_ip_ubuntu" {
  value = aws_instance.ec2server.public_ip
}

resource "aws_network_interface" "newinterface1" {
  subnet_id       = aws_subnet.publicsubnet.id
  private_ips     = ["10.0.0.7"]
  security_groups = [aws_security_group.vpcnewsg.id]

  attachment {
    instance     = aws_instance.ec2server.id
    device_index = 1
}
}

#### Allocate ElasticIp
resource "aws_eip" "elasticip" {
    domain   = "vpc"
}

resource "aws_eip_association" "elasticip" {
  network_interface_id = aws_network_interface.newinterface1.id
  allocation_id        = aws_eip.elasticip.id
}

output "elastic_ip" {
  value = aws_eip.elasticip.public_ip
}


##### Create S3 bucket
resource "aws_s3_bucket" "s3_bucket" {
    
    bucket = "taskbucket45"
    acl = "private"
}

resource "aws_dynamodb_table" "dynamodb-tf-state-lock" {
  name = "tf-state-lock-dynamo"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
 
  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket = "taskbucket45"
    dynamodb_table = "tf-state-lock-dynamo"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
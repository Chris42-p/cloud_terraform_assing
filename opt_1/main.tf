# =============== Option 1 Assignment: Make a VPC  ==========
#   By: Chris 
#   Date: 3/28'26

# move from the internet into the network 
# VPC-> Internet gateway-> IP -> Public network -> NAT -> Private network -> S3 Endpoint
# ===========================================================

#aws infrastructure 
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Owner   = "Chris"
      Teacher = "Denis"
      Assign  = "Cloud Infra assign"
    }
  }
  #ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
}
locals {
  public_subnets = {
    zone1 = { cidr = var.public_subnet_one, az = var.availability_zone_one }
    zone2 = { cidr = var.public_subnet_two, az = var.availability_zone_two }
  }

  private_subnets = {
    zone1 = { cidr = var.private_subnet_one, az = var.availability_zone_one }
    zone2 = { cidr = var.private_subnet_two, az = var.availability_zone_two }
  }
}

# Give access into network 
#----------------------VPC -----------------------   
resource "aws_vpc" "main" {
  cidr_block           = var.VPC_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true #allow DNS in the network ("example.io" ->10.0.1.2 )

  tags = {
    Name        = "Assignment-VPC"
    Description = "VPC"
  }
  # reg:https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
}
#----------------------Internet Gateway --------
resource "aws_internet_gateway" "main" { #give VPC internet  
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "Assignment-Internet-Gateway"
    Description = "Internet gateway for the public VPC"
  }
  depends_on = [aws_vpc.main]

  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
}
#---------------------Elastic IP ---------------
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name        = "Assignment-Elastic-IP"
    Description = "Elastic IP for the NAT gateway"
  }
  depends_on = [aws_internet_gateway.main]
  # ref:https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
}
#------------ Nat Gateway-----------------------
resource "aws_nat_gateway" "private_network" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[keys(local.public_subnets)[0]].id #going to route private traffic through public subnet

  tags = {
    Name        = "Assignment-NAT-Gateway"
    Description = "NAT gateway for private subnet"
  }
  depends_on = [aws_internet_gateway.main]
}
#-------------------------------------------------

# The public network 
#--------------------Public network---------------------   
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id #connect to VPC 

  for_each          = local.public_subnets #loop over values. 
  cidr_block        = each.value.cidr      #cidr values assignment
  availability_zone = each.value.az        #availability zones assignment

  tags = {
    Name        = "Public Subnet ${each.key}/${length(local.public_subnets)}"
    Description = "Public subnet for the VPC"
  }

  depends_on = [aws_vpc.main]
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
}
#--------------------Public network route table -------- 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.internet_route           #send outbound traffic to internet 
    gateway_id = aws_internet_gateway.main.id #send to internet gateway
  }
  tags = {
    Name        = "Public Route Table"
    Description = "Route table for the public subnet"
  }
  depends_on = [aws_internet_gateway.main]
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
}
resource "aws_route_table_association" "public" {
  for_each       = local.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

  depends_on = [aws_route_table.public]
}
#-------------------------------------------------------


# The private network 
#------------ Private Network -----------------
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  for_each          = local.private_subnets
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name        = "Private subnet ${each.key} /${length(local.private_subnets)}"
    Description = "Private subnet for VPC"
  }
  depends_on = [aws_vpc.main]
}

#-------------Private network routing table----
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0" #allow outbound traffic 
    nat_gateway_id = aws_nat_gateway.private_network.id
  }

  tags = {
    Name        = "Private Route Table"
    Description = "Route table for private subnet"
  }
  depends_on = [aws_nat_gateway.private_network]

  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
}
resource "aws_route_table_association" "private" {
  for_each       = local.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id

  depends_on = [aws_route_table.private]
}
#----------------------------------------------

#S3 VPC endpoint
#-------------------S3 endpoint-------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.main.id

  service_name = "com.amazonaws.${var.region}.s3"

  #loop through private tables, and associcate Ids
  route_table_ids = [aws_route_table.private.id]

  tags = {
    Name        = "VPC S3 Endpoint"
    Description = "S3 endpoint for private subnets only"
  }

  depends_on = [aws_route_table.private]

  # ref:https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint.html  
}
#-------------------------------------------------



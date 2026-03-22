#config of AWS provider 
provider "aws" {
  region = var.availability_region_one

  default_tags {
    tags = {
      Owner = "Chris"
      Name  = "BCIT_cloud_assignment"
      Env   = "dev"
    }
  }
}

locals {
  #availability zones. 
  availability_zones=  [var.availability_region_one, var.availability_region_two]

  #CIDR for public and private
  public_subnet_cidrs=[var.public_subnet_one, var.public_subnet_two]
  private_subnet_cidrs=[var.private_subnet_one,var.private_subnet_two]
}


#Create VPC 
resource "aws_vpc" "BCIT_cloud_assign" {
  cidr_block = var.VPC_cidr_block

  #DNS settings 
  enable_dns_hostnames = true #Assign public DNS hostname to instances in public Ips
  enable_dns_support   = true #Enable DNS resolution within the VPC

  tags = {
    Description=""
  }
}

#two public and two private subnets
  #two public 
resource "aws_subnet" "public" {
  #availability zones and VPC 
  availability_zone = local.availability_zones
  vpc_id            = aws_vpc.BCIT_cloud_assign

  #setting two networks with CIDR addresses. 
  count =length(local.public_subnet_cidrs)
  cidr_block = local.public_subnet_cidrs[count.index] # index throught to assign cidr addresses

  tags ={
    Description=""
    Subnet="public_${local.public_subnet_cidrs[count.index]}" #name it properly
  }

}
  #two private 
resource "aws_subnet" "private" {
  #set up the availability zones
  availability_zone = local.availability_zones  
  vpc_id = aws_vpc.BCIT_cloud_assign

  #set up the networks
  count = length(local.private_subnet_cidrs)
  cidr_block = local.private_subnet_cidrs[count.index]

  tags ={
    Description=""
    Subnet="private_${local.public_subnet_cidrs[count.index]}" #name it properly
  }
}


#one regional NAT gatewat.
  #create Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.BCIT_cloud_assign.id #assign gateway to VPC

  tags = {
    Description="The internet gateway for the VPC"
    Name="main internet gateway"
  }
}

  #create elastic IP for NAT 
resource "aws_eip" "NAT" {
  #assign gateway to NAT
  domain = "vpc"
  depends_on = [ aws_internet_gateway.main ]

  tags = {
    Description= "assigned elastic IP that will be attached to NAT"
    Name= "nat-eip"
  }
}

  #NAT gateway
resource "aws_nat_gateway" "vpc_gateway" {
  allocation_id = aws_eip.NAT.id
  subnet_id = aws_subnet.public[0].id #place routing into public subnet
  depends_on = [ aws_internet_gateway.main ]

  tags = {
    Description =""
    Name="nat-gateway"
  }
}
  
  #routing table  
    #private 
resource "aws_route_table" "private" {
  vpc_id=aws_vpc.BCIT_cloud_assign

  route{
    cidr_block = var.internet_route
    nat_gateway_id = aws_nat_gateway.vpc_gateway
  }

  tags = {
    Description="This is the routing table for the private subnet"
    Name="private route table"
  }
}
    #public 
resource "aws_route_table" "public" {
  vpc_id= aws_vpc.BCIT_cloud_assign

  route {
    cidr_block = var.internet_route #route to the internet
    nat_gateway_id = aws_eip.NAT.id
  }
    
  tags = {
    Description="This is the routing table for the public subnet"
    Name="private route table"
  }
}

  #attach routing table to subnets. 
    #private
resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.private.id

  count =length(local.private_subnet_cidrs)
  subnet_id = aws_subnet.private[count.index].id
}
    #public 
resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public

  count = length(local.public_subnet_cidrs)
  subnet_id = aws_subnet.public[count.index].id
}


#VPC endpoint for S3 for private subnets only 
resource "aws_vpc_endpoint" "s3" {
  vpc_id = aws_vpc.BCIT_cloud_assign.id
  route_table_ids = aws_route_table.private.id

  service_name = "com.amazonaws.${var.availability_region_one}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name="s3-endpoint"
    Description="Let private VPC requests access s3 bucket"
  }
}

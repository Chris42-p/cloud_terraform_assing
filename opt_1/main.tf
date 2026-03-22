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
#two availability zones 

#Create VPC 
resource "aws_vpc" "BCIT_cloud_assign" {
  cidr_block = var.VPC_cidr_block

  #DNS settings 
  enable_dns_hostnames = true #Assign public DNS hostname to instances in public Ips
  enable_dns_support   = true #Enable DNS resolution within the VPC
}

#two public and two private subnets
  #two public 
resource "aws_subnet" "public" {
  availability_zone = [var.availability_region_one, var.availability_region_two]
  vpc_id            = aws_vpc.BCIT_cloud_assign
  count=2
}



#one regional NAT gatewat. 

#subnet routing

#VPC endpoint for S3 for private subnets only 


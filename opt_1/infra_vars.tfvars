#VPC cider
VPC_cidr_block = "10.0.0.0/16"

#availability zones. 
num_availability_zones = 2
availability_region_one = "ca-center-1"
availability_region_two = "ca-east-1"

#route to internet
internet_route = "0.0.0.0/0"

#public subnet ranges
public_subnet_one = "10.0.1.0/24"
public_subnet_two = "10.0.2.0/24"

#private subent ranges
private_subnet_one = "10.0.10.0/24"
private_subnet_two = "10.0.11.0/24"

#tags
public_tag  = "public"
private_tag = "private"

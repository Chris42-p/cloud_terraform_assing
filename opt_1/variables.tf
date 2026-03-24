variable "VPC_cidr_block" {
    description = "the cider block of the VPC"
    type = string
}
#region 
variable "availability_region_one" {
    description = "availability region one"
    type = string
}
variable "availability_region_two" {
    description = "availability region two"
    type = string
}
variable "num_availability_zones" {
    description = "number of availability zones"
    type = number
}

#subnet descriptions.
    #forward to the internet
variable "internet_route" {
    description = "default route to the internet"
    type = string
}

    #public 
variable "public_subnet_one" {
    description = "public subnet one "
    type = string
}
variable "public_subnet_two" {
    description = "public subnet two "
    type = string
}

    #private
variable "private_subnet_one" {
    description = "private subnet one"
    type = string
}
variable "private_subnet_two" {
    description = "private subnet two"
    type = string 
}

#tags 
variable "public_tag" {
  description = "public"
  type = string
}
variable "private_tag" {
    description = "private"
    type = string
}
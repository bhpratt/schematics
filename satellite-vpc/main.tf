# name of VPC
resource "ibm_is_vpc" "vpc1" {
  name = var.vpc_name
  # Only one VPC per region can have classic access
  classic_access = var.classic_access
  resource_group = local.rg_id
}

# remove this after testing
locals {
  rg_id = data.ibm_resource_group.resource_group.id
}

# name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# VPC subnets. Uses default CIDR range
resource "ibm_is_subnet" "subnet1" {
  name                     = "${var.region}-1"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway_subnet1.id
  resource_group = local.rg_id
}

# Uncomment to add additional subnets
# resource "ibm_is_subnet" "subnet2" {
#   name                     = "${var.region}-2"
#   vpc                      = ibm_is_vpc.vpc1.id
#   zone                     = "${var.region}-2"
#   total_ipv4_address_count = 256
#   resource_group = local.rg_id
# }

# resource "ibm_is_subnet" "subnet3" {
#   name                     = "${var.region}-3"
#   vpc                      = ibm_is_vpc.vpc1.id
#   zone                     = "${var.region}-3"
#   total_ipv4_address_count = 256
#   resource_group = local.rg_id
# }

# Include public gateway for connectivity outside of VPC
# To remove public gateway, cancel out this block and line in subnet1
resource "ibm_is_public_gateway" "gateway_subnet1" {
  name       = "vpcgen2-gateway"
  vpc        = ibm_is_vpc.vpc1.id
  zone       = "${var.region}-1"
  resource_group = local.rg_id

  //User can configure timeouts
  timeouts {
     create = "90m"
  }
 }
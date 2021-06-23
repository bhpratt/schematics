# COS instance for registry backup
resource "ibm_resource_instance" "cos_instance" {
  name     = var.service_instance_name
  service  = var.service_offering
  plan     = var.plan
  location = "global"
}

# name of VPC
resource "ibm_is_vpc" "vpc1" {
  name = var.vpc_name
  # Only one VPC per region can have classic access
  classic_access = var.classic_access
}

# name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

 # Include public gateway for connectivity outside of VPC
 resource "ibm_is_public_gateway" "gateway_subnet1" {
    name       = "vpcgen2-iks-gateway"
    vpc        = ibm_is_vpc.vpc1.id
    zone       = "${var.region}-1"

    //User can configure timeouts
    timeouts {
        create = "90m"
    }
}

# VPC subnets. Uses default CIDR range
resource "ibm_is_subnet" "subnet1" {
  name                     = "${var.region}-1"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway_subnet1.id
}

# uncomment to create a multizone cluster
# resource "ibm_is_subnet" "subnet2" {
#   name                     = "${var.region}-2"
#   vpc                      = ibm_is_vpc.vpc1.id
#   zone                     = "${var.region}-2"
#   total_ipv4_address_count = 256
# }

# resource "ibm_is_subnet" "subnet3" {
#   name                     = "${var.region}-3"
#   vpc                      = ibm_is_vpc.vpc1.id
#   zone                     = "${var.region}-3"
#   total_ipv4_address_count = 256
#}

# ROKS cluster. Single zone.
resource "ibm_container_vpc_cluster" "cluster" {
  name                            = var.name
  vpc_id                          = ibm_is_vpc.vpc1.id
  flavor                          = var.flavor
  kube_version                    = (var.kube_version != null ? var.kube_version : null)
  worker_count                    = var.worker_count
  disable_public_service_endpoint = var.public_service_endpoint_disabled
  resource_group_id               = data.ibm_resource_group.resource_group.id
  cos_instance_crn                = ibm_resource_instance.cos_instance.id
  wait_till                       = "OneWorkerNodeReady"


  zones {
    subnet_id = ibm_is_subnet.subnet1.id
    name      = "${var.region}-1"
  }

  # uncomment to create a multizone cluster
  # zones {
  #   subnet_id = ibm_is_subnet.subnet2.id
  #   name      = "${var.region}-2"
  # }

  # zones {
  #   subnet_id = ibm_is_subnet.subnet3.id
  #   name      = "${var.region}-3"
  # }
}
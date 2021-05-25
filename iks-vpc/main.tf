terraform {
     required_providers {
        ibm = {
           source = "IBM-Cloud/ibm"
           }
      }
  required_version = ">= 0.12"
}


# specifies gen2 and region for VPC/IKS resources
provider "ibm" {
  region = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
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

resource "ibm_is_subnet" "subnet2" {
  name                     = "${var.region}-2"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-2"
  total_ipv4_address_count = 256
}

resource "ibm_is_subnet" "subnet3" {
  name                     = "${var.region}-3"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-3"
  total_ipv4_address_count = 256
}

# IKS cluster. Single zone.
resource "ibm_container_vpc_cluster" "cluster" {
  name                 = var.name
  vpc_id               = ibm_is_vpc.vpc1.id
  flavor               = var.flavor
  kube_version         = (var.kube_version != null ? var.kube_version : null)
  patch_version        = (var.patch_version != null ? var.patch_version : null)
  worker_count         = var.worker_count
  resource_group_id    = data.ibm_resource_group.resource_group.id
  force_delete_storage = var.delete_storage
  # Lets Schematics/Terraform start working with the cluster as soon as a node is available
  wait_till            = "OneWorkerNodeReady"

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
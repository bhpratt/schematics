# specifies gen2 and region for VPC/IKS resources
provider "ibm" {
  generation = 2
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

# required inbound connectivity for VPC LB traffic to worker nodes
# https://cloud.ibm.com/docs/containers?topic=containers-clusters#clusters_vpcg2
resource "ibm_is_security_group_rule" "security_group_rule_default_tcp" {
    group = ibm_is_vpc.vpc1.default_security_group
    direction = "inbound"
    tcp {
      port_min = 30000
      port_max = 32767
    }
 }

 resource "ibm_is_security_group_rule" "security_group_rule_default_udp" {
    group = ibm_is_vpc.vpc1.default_security_group
    direction = "inbound"
    udp {
      port_min = 30000
      port_max = 32767
    }
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
  name              = var.name
  vpc_id            = ibm_is_vpc.vpc1.id
  flavor            = var.flavor
  worker_count      = var.worker_count
  resource_group_id = data.ibm_resource_group.resource_group.id
  # Lets Schematics/Terraform start working with the cluster as soon as a node is available
  wait_till         = "OneWorkerNodeReady"

  zones {
    subnet_id = ibm_is_subnet.subnet1.id
    name      = "${var.region}-1"
  }

  # uncomment to create a multizone cluster
  zones {
    subnet_id = ibm_is_subnet.subnet2.id
    name      = "${var.region}-2"
  }

  zones {
    subnet_id = ibm_is_subnet.subnet3.id
    name      = "${var.region}-3"
  }
}
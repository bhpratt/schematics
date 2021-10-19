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
}

# name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# get the list of available cluster versions in IBM Cloud
data "ibm_container_cluster_versions" "cluster_versions" {
}

# required inbound connectivity for VPC LB traffic to worker nodes for openshift 4.4 clusters and earlier
# https://cloud.ibm.com/docs/openshift?topic=openshift-clusters#clusters_vpcg2
# resource "ibm_is_security_group_rule" "security_group_rule_default_tcp" {
#     group = ibm_is_vpc.vpc1.default_security_group
#     direction = "inbound"
#     tcp {
#       port_min = 30000
#       port_max = 32767
#     }
#  }

#  resource "ibm_is_security_group_rule" "security_group_rule_default_udp" {
#     group = ibm_is_vpc.vpc1.default_security_group
#     direction = "inbound"
#     udp {
#       port_min = 30000
#       port_max = 32767
#     }
#  }

  # Include public gateway for connectivity outside of VPC
 resource "ibm_is_public_gateway" "gateway_subnet1" {
    name       = "vpc-gen2-roks-gateway"
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

# uncomment to create multizone cluster
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
# }

# ROKS cluster. Single zone.
resource "ibm_container_vpc_cluster" "cluster" {
  //*TO DO*: figure out how to make this container_index work ? maybe locals? https://www.terraform.io/docs/language/values/locals.html#declaring-a-local-value
  #container_index = length(data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions) - 2
  name                            = var.name
  vpc_id                          = ibm_is_vpc.vpc1.id
  flavor                          = var.flavor
  #*TO DO* need to tag version with _openshift at the end: https://stackoverflow.com/questions/63443283/how-to-concatenate-a-variable-and-a-string-in-terraform
  kube_version                    = (var.kube_version != null ? var.kube_version : "${data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions[2]}_openshift")
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
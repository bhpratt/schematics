# Pick the second to last supported version of OpenShift as the version to use for the cluster
locals {
  index = length(data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions) - 2
}

# COS instance for registry backup
resource "ibm_resource_instance" "cos_instance" {
  name     = var.service_instance_name
  service  = var.service_offering
  plan     = var.plan
  location = "global"
}

# Name of VPC
resource "ibm_is_vpc" "vpc" {
  name = var.vpc_name
}

# Name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# List of available cluster versions in IBM Cloud
data "ibm_container_cluster_versions" "cluster_versions" {
}

# Public gateway to allow connectivity outside of the VPC
 resource "ibm_is_public_gateway" "gateway_subnet" {
    count      = var.zone_count
    name       = "${var.region}-${count.index + 1}"
    vpc        = ibm_is_vpc.vpc.id
    zone       = "${var.region}-${count.index + 1}"

    //User can configure timeouts
    timeouts {
        create = "90m"
    }
}

# VPC subnets. Uses default CIDR range
resource "ibm_is_subnet" "subnet" {
  count                    = var.zone_count
  name                     = "${var.region}-${count.index + 1}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.region}-${count.index + 1}"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway_subnet[count.index].id
}

# OpenShift cluster. Defaults to single zone. Version by default will take the 2nd to last in the list of the valid openshift versions given in the output of `ibmcloud oc versions`
resource "ibm_container_vpc_cluster" "cluster" {
  name                            = var.name
  vpc_id                          = ibm_is_vpc.vpc.id
  flavor                          = var.flavor
  kube_version                    = (var.kube_version != null ? var.kube_version : "${data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions[local.index]}_openshift")
  worker_count                    = var.worker_count
  disable_public_service_endpoint = var.public_service_endpoint_disabled
  resource_group_id               = data.ibm_resource_group.resource_group.id
  cos_instance_crn                = ibm_resource_instance.cos_instance.id
  wait_till                       = "OneWorkerNodeReady"



    dynamic zones {
    for_each = ibm_is_subnet.subnet
    content {
      name      = zones.value.name
      subnet_id = zones.value.id
    }
  }
}

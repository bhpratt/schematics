# data "ibm_container_cluster_config" "cluster_config" {
#   # update this value with the Id of the cluster where these agents will be provisioned
#   cluster_name_id = ibm_container_vpc_cluster.cluster.id
# }

locals {
  # Add randomized string to name to prevent name duplication
  name = "${var.name}-${random_string.id.result}"
}

# Create random string to append to name
resource "random_string" "id" {
  length  = 4
  special = false
  upper   = false
}

# Name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# Virtual Private Cloud (VPC)
resource "ibm_is_vpc" "vpc" {
  name = local.name
}

# Public gateway to allow connectivity outside of the VPC
resource "ibm_is_public_gateway" "gateway_subnet" {
  count = var.number_of_zones
  name  = "${local.name}-publicgateway-${count.index + 1}"
  vpc   = ibm_is_vpc.vpc.id
  zone  = "${var.region}-${count.index + 1}"

  //User can configure timeouts
  timeouts {
    create = "90m"
  }
}

# VPC subnets. Uses default CIDR range
resource "ibm_is_subnet" "subnet" {
  count                    = var.number_of_zones
  name                     = "${local.name}-subnet-${count.index + 1}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.region}-${count.index + 1}"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway_subnet[count.index].id
}

# List of available cluster versions in IBM Cloud
data "ibm_container_cluster_versions" "cluster_versions" {
}

# OpenShift cluster. Defaults to single zone. Version by default will take the 2nd to last in the list of the valid openshift versions given in the output of `ibmcloud oc versions`
resource "ibm_container_vpc_cluster" "cluster" {
  name                            = local.name
  vpc_id                          = ibm_is_vpc.vpc.id
  flavor                          = var.worker_flavor
  kube_version                    = (var.kube_version != null ? var.kube_version : "${data.ibm_container_cluster_versions.cluster_versions.default_openshift_version}_openshift")
  worker_count                    = var.workers_per_zone
  disable_public_service_endpoint = var.public_service_endpoint_disabled
  operating_system                = var.operating_system
  resource_group_id               = data.ibm_resource_group.resource_group.id
  cos_instance_crn                = ibm_resource_instance.cos_instance.id
  wait_till                       = "OneWorkerNodeReady"

  dynamic "zones" {
    for_each = ibm_is_subnet.subnet
    content {
      name      = zones.value.zone
      subnet_id = zones.value.id
    }
  }
}

# COS instance for cluster registry backup
resource "ibm_resource_instance" "cos_instance" {
  name     = local.name
  service  = var.service_offering
  plan     = var.plan
  location = "global"
}

##############################################################################
# Observability Agents
##############################################################################


# module "observability_agents" {
#   # source                        = "git@github.com:terraform-ibm-modules/terraform-ibm-observability-agents.git?ref=1.21.1"
#   source                        = "terraform-ibm-modules/observability-agents/ibm"
#   version                       = "1.21.1"
#   cluster_id                    = ibm_container_vpc_cluster.cluster.id
#   cluster_resource_group_id     = data.ibm_resource_group.resource_group.id
#   log_analysis_instance_region  = "us-south"
#   log_analysis_ingestion_key    = "6b39df3178511574b1a2c14abda97411"
#   cloud_monitoring_access_key   = "94b3777f-54e9-4a2f-b90f-2b931b09cb69"
#   cloud_monitoring_instance_region = "us-east"
#   log_analysis_add_cluster_name = true
# }
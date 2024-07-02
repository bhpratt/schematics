# name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# List of available cluster versions in IBM Cloud
data "ibm_container_cluster_versions" "cluster_versions" {
}

# IKS cluster. Single zone.
resource "ibm_container_cluster" "cluster" {
  name              = var.name
  machine_type      = var.machine_type
  resource_group_id = data.ibm_resource_group.resource_group.id
  datacenter        = var.datacenter
  kube_version      = (var.kube_version != null ? var.kube_version : data.ibm_container_cluster_versions.cluster_versions.default_kube_version)
  public_vlan_id    = ibm_network_vlan.public_vlan.id
  private_vlan_id   = ibm_network_vlan.private_vlan.id
  hardware          = "shared"
  default_pool_size = var.default_pool_size
  private_service_endpoint = var.private_service_endpoint_enabled
  public_service_endpoint  = var.public_service_endpoint_enabled
  wait_till = "OneWorkerNodeReady"
}

resource "ibm_network_vlan" "public_vlan" {
  name            = "${var.name}-public"
  datacenter      = var.datacenter
  type            = "PUBLIC"
}

resource "ibm_network_vlan" "private_vlan" {
  name            = "${var.name}-private"
  datacenter      = var.datacenter
  type            = "PRIVATE"
}
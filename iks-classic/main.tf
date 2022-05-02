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
}

# name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# IKS cluster. Single zone.
resource "ibm_container_cluster" "cluster" {
  name              = var.name
  machine_type      = var.machine_type
  resource_group_id = data.ibm_resource_group.resource_group.id
  datacenter        = var.datacenter
  public_vlan_id    = var.public_vlan_id
  private_vlan_id   = var.private_vlan_id
  hardware          = "shared"
  default_pool_size = var.default_pool_size
  private_service_endpoint = var.private_service_endpoint_enabled
  public_service_endpoint  = var.public_service_endpoint_enabled
}

# resource "ibm_container_worker_pool_zone_attachment" "zone2" {
#   cluster           = ibm_container_cluster.cluster.id
#   worker_pool       = ibm_container_cluster.cluster.worker_pools.0.id
#   zone              = var.datacenter_zone2
#   private_vlan_id   = var.private_vlan_id_zone2
#   public_vlan_id    = var.public_vlan_id_zone2
#   resource_group_id = data.ibm_resource_group.resource_group.id
# }

# resource "ibm_container_worker_pool_zone_attachment" "zone3" {
#   cluster           = ibm_container_cluster.cluster.id
#   worker_pool       = ibm_container_cluster.cluster.worker_pools.0.id
#   zone              = var.datacenter_zone3
#   private_vlan_id   = var.private_vlan_id_zone3
#   public_vlan_id    = var.private_vlan_id_zone3
#   resource_group_id = data.ibm_resource_group.resource_group.id
# }
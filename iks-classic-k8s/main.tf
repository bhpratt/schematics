# specifies gen2 and region for VPC/IKS resources
provider "ibm" {
  region = var.region
}

provider "kubernetes" {}

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
  private_service_endpoint = "true"
  public_service_endpoint  = "true"
}

resource "kubernetes_namespace" "new-ns" {
  metadata {
    name = var.namespace
  }
}

# resource "kubernetes_secret" "example" {
#   metadata {
#     name = "basic-auth"
#     namespace = var.namespace
#   }

#   data = {
#     username = "admin"
#     password = "passw4rd"
#   }
# }
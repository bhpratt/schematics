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
  # private_service_endpoint = "true"
  # public_service_endpoint  = "true"
# running some no subnet cluster test
  no_subnet = "true"
  #subnet = "1921661"
}


resource "null_resource" "subnet_add" {

  provisioner "local-exec" {
    command = <<EOT
      ibmcloud login -c ${var.account_id} --apikey ${var.ibm_cloud_api_key} -g ${var.resource_group} -r ${var.region} \
      && ibmcloud ks cluster subnet add --cluster ${var.name} --subnet-id ${var.subnet_id}
      EOT
    }
  
  #tells resource to wait on cluster creation
  depends_on = [ibm_container_cluster.cluster]
  
}

# did not succeed
# resource "null_resource" "add_subnet" {
#   provisioner "local-exec" {
#     command = "ibmcloud ks cluster subnet add --cluster ${var.name} --subnet-id ${var.subnet_id}"
#   }

#   depends_on = [ibm_container_cluster.cluster]
# }

#review for other ideas https://github.com/IBM-Cloud/terraform-provider-ibm/issues/900
# specifies gen2 and region for VPC/IKS resources
provider "ibm" {
  region = var.region
}

# review this doc: https://cloud.ibm.com/docs/terraform?topic=terraform-container-data-sources#container-cluster-config-sample
provider "kubernetes" {
  config_path = data.ibm_container_cluster_config.clusterConfig.config_file_path
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
  private_service_endpoint = "true"
  public_service_endpoint  = "true"
  wait_till         = "OneWorkerNodeReady"
}

data "ibm_container_cluster_config" "clusterConfig" {

  cluster_name_id = ibm_container_cluster.cluster.name
  config_dir = "/tmp"
  # depends_on = [
  #   ibm_container_cluster.cluster,
  # ]
}

resource "kubernetes_namespace" "newNamespace" {
  metadata {
    name = var.namespace
  }
  # depends_on = [
  #   ibm_container_cluster.cluster,
  # ]
}

resource "kubernetes_secret" "loginSecret" {
  metadata {
    name = "login"
    namespace = var.namespace
  }

  data = {
    "login" = var.login_key
  }
  # depends_on = [
  # ]
}

resource "kubernetes_secret" "stagingSecret" {
  metadata {
    name = "staging"
    namespace = var.namespace
  }

  data = {
    "login-staging" = var.staging_key
  }
  # depends_on = [
  # ]
}

resource "kubernetes_secret" "ibmcloudCliSecret" {
  metadata {
    name = "ibm-cloud-cli"
    namespace = var.namespace
  }

  data = {
    "apikey" = var.ibmcloud_cli_key
  }
  # depends_on = [
  #   provider.kubernetes,
  # ]
}

# resource "null_resource" "example1" {
#   provisioner "local-exec" {
#     command = <<EOT
#       kubectl get secret all-icr-io -n default -o yaml | sed 's/default/cli-tool/g' | kubectl create -n cli-tool -f -
#       EOT
#     }
# }
##############################################################################
# Terraform Providers
##############################################################################

terraform {
     required_providers {
        ibm = {
           source = "IBM-Cloud/ibm"
           }
      }
  required_version = ">= 0.13"
}

##############################################################################

##############################################################################
# IBM Cloud Provider
##############################################################################

provider "ibm" {
  region = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
}

##############################################################################


##############################################################################
# Kubernetes Provider
# review these examples: https://cloud.ibm.com/docs/terraform?topic=terraform-container-data-sources#container-cluster-config-sample
# https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/container_cluster_config
##############################################################################
 provider "kubernetes" {
   # alternate config style
   # config_path = data.ibm_container_cluster_config.clusterConfig.config_file_path
   # load_config_file       = "false"
   host                   = data.ibm_container_cluster_config.clusterConfig.host
   token                  = data.ibm_container_cluster_config.clusterConfig.token
   cluster_ca_certificate = data.ibm_container_cluster_config.clusterConfig.ca_certificate
 }

 ##############################################################################

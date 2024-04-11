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
  region = var.cluster_region
  # uncomment if using local terraform
  ibmcloud_api_key = var.ibmcloud_api_key
}

provider "helm" {
  kubernetes {
    host                   = data.ibm_container_cluster_config.cluster_config.host
    token                  = data.ibm_container_cluster_config.cluster_config.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
  }
}

##############################################################################
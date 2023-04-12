##############################################################################
# Terraform Providers
##############################################################################

terraform {
     required_providers {
        ibm = {
           source = "IBM-Cloud/ibm"
           version = ">= 1.50"
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
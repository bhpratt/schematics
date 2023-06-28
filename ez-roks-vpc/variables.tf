# IBM provider variables
# uncomment if using local terraform
# variable "ibmcloud_api_key" {}

# Global variables
variable "name" {
  default = "ez-openshift-vpc"
}

variable "region" {
  default = "us-east"
}

variable "resource_group" {
  default = "default"
}

variable "number_of_zones" {
  default = 1
}


# OpenShift variables
variable "flavor" {
  default = "bx2.4x16"
}

variable "workers_per_zone" {
  default = "2"
}

variable "public_service_endpoint_disabled" {
  default = false
}

variable "kube_version" {
  type    = string
  default = null
}

# Cloud Object Storage variables
variable "service_instance_name" {
  default = "roks-gen2"
}

variable "service_offering" {
  default = "cloud-object-storage"
}

variable "plan" {
  default = "standard"
}
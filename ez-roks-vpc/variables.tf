#IBM provider variables
//uncomment if using local terraform
# variable "ibmcloud_api_key" {}

# VPC variables

# OpenShift variables
variable "flavor" {
  default = "bx2.4x16"
}
variable "worker_count" {
  default = "2"
}

variable "region" {
  default = "br-sao"
}

variable "resource_group" {
  default = "default"
}

variable "public_service_endpoint_disabled" {
  default = false
}

variable "name" {
  default = "vpc-gen2-roks"
}

variable "kube_version" {
  type = string
  default = null
}

variable "vpc_name" {
  default = "vpz-openshift"
}

variable "zone_count" {
  default = 3
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
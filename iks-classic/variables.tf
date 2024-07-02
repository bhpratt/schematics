variable "ibmcloud_api_key" {}

variable "machine_type" {
  default = "b3c.4x16"
}

variable "region" {
  default = "us-east"
}

variable "resource_group" {
  default = "default"
}

variable "name" {
  default = "iks-classic"
}

variable "kube_version" {
  default = null
}


variable "datacenter" {
  default = "wdc07"
}

variable "default_pool_size" {
  default = "2"
}

variable "public_service_endpoint_enabled" {
  default = true
}

variable private_service_endpoint_enabled {
  default = true
}
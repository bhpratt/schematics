# COS variables
variable "service_instance_name" {
  default = "roks-gen2"
}

variable "service_offering" {
  default = "cloud-object-storage"
}

variable "plan" {
  default = "standard"
}


variable "flavor" {
  type = string
  default = "bx2.4x16"
}
variable "worker_count" {
  type = number
  default = 2
}

variable "region" {
  type = string
  default = "us-east"
}

variable "resource_group" {
  type = string
  default = "default"
}

variable "name" {
  type = string
  default = "roks-vpc-private"
}

variable "vpc_name" {
  type = string
  default = "roks-vpc-private"
}

variable "kube_version" {
  type = string
  default = null
}

variable "patch_version" {
  type = string
  default = null
}

variable "update_all_workers" {
  type = bool
  default = false
}

variable "classic_access" {
  type = string
  default = "false"
}

variable "delete_storage" {
  type = bool
  description = "Choose whether you want storage created by the cluster to be deleted at the same time as the cluster"
  default = true
}

variable "ibmcloud_api_key" {}

variable "public_service_endpoint_disabled" {
  default = true
}
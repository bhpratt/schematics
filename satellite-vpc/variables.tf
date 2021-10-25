variable "region" {
  type = string
  default = "us-east"
}

variable "resource_group" {
  type = string
  default = "default"
}

variable "vpc_name" {
  type = string
  default = "satellite-vpc"
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
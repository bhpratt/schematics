
variable "flavor" {
  type = string
  default = "bx2.4x16"
}
variable "worker_count" {
  type = number
  default = 3
}

variable "region" {
  type = string
  default = "br-sao"
}

variable "resource_group" {
  type = string
  default = "default"
}

variable "name" {
  type = string
  default = "iks-vpc"
}

variable "vpc_name" {
  type = string
  default = "iks-vpc"
}

variable "kube_version" {
  type = string
  default = null
}

variable "operating_system" {
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
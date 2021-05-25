
variable "flavor" {
  type = string
  default = "bx2.2x8"
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
  default = "iks-vpc-k8s"
}

variable "vpc_name" {
  type = string
  default = "iks-vpc-k8s"
}

variable "kube_version" {
  type = string
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
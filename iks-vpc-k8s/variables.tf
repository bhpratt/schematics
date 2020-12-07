
variable "flavor" {
  default = "bx2.2x8"
}
variable "worker_count" {
  default = "2"
}

variable "region" {
  default = "us-east"
}

variable "resource_group" {
  default = "default"
}

variable "name" {
  default = "iks-vpc-k8s"
}

variable "vpc_name" {
  default = "iks-vpc-k8s"
}

variable "classic_access" {
  default = "false"
}

variable "ibmcloud_api_key" {}
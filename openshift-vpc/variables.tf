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

# IKS/ROKS Variables
variable "flavor" {
  default = "bx2.4x16"
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

variable "public_service_endpoint_disabled" {
  default = false
}

variable "name" {
  default = "vpc-gen2-roks"
}

variable "kube_version" {}

variable "vpc_name" {
  default = "vpz-openshift"
}
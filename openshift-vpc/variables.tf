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

variable "name" {
  default = "cluster"
}

variable "kube_version" {
  default = "4.3.23_openshift"
}

variable "vpc_name" {
  default = "vpz"
}

variable "machine_type" {
  default = "b2c.4x16"
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

variable "public_vlan_id" {}

variable "private_vlan_id" {}

variable "datacenter" {
  default = "wdc07"
}

variable "default_pool_size" {
  default = "1"
}

variable "account_id" {}

variable "ibm_cloud_api_key" {}

variable "subnet_id" {}
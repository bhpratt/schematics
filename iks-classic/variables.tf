
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
  default = "iks-cluster"
}

variable "public_vlan_id" {
  default = null
}

variable "private_vlan_id" {
  default = null
}

variable "public_vlan_id_zone2" {
  default = null
}

variable "private_vlan_id_zone2" {
  default = null
}

variable "public_vlan_id_zone3" {
  default = null
}

variable "private_vlan_id_zone3" {
  default = null
}

variable "datacenter" {
  default = "wdc07"
}

variable "datacenter_zone2" {
  default = "wdc04"
}

variable "datacenter_zone3" {
  default = "wdc06"
}

variable "default_pool_size" {
  default = "3"
}

variable "public_service_endpoint_enabled" {
  default = true
}

variable private_service_endpoint_enabled {
  default = true
}
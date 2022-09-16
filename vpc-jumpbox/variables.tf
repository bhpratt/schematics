variable "vpc_name" {
  type = string
  default = "satellite-vpc"
}

variable "classic_access" {
  type = string
  default = "false"
}

variable "resource_group" {
  type = string
  default = "default"
}

variable "ibmcloud_api_key" {}

variable "my_ip" {}

variable "jumpbox_image" {
  type = string
  //ibm-centos-7-9-minimal-amd64-6 | ibmcloud is images
  default = "r014-ef74036d-4b4b-4ba2-b592-aaf2190e0079"
}

variable "jumpbox_floating_ip_name" {
  type = string
  default = "jumpbox-ip"
}

variable "jumpbox_name" {
  type = string
  default = "jumpbox-vpc"
}

variable "jumpbox_profile" {
  type = string
  default = "bx2-2x8"
}

variable "login_account_id" {}

variable "login_region" {
  type = string
  default = "us-east"
}

variable "login_username" {}

variable "openshift_version" {
  type = string
  default = "4.10.0"
}

variable "security_group_name" {
  type = string
  default = "allow-inbound"
}

variable "ssh_key" {}

variable "vpc_name" {
  type = string
  default = "r014-3d056da0-0771-4d5a-91ce-5a826667bd05"
}

variable "region" {
  type = string
  default = "us-east"
}



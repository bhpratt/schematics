
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

variable "classic_access" {
  type = string
  default = "false"
}

variable "delete_storage" {
  type = bool
  description = "Choose whether you want storage created by the cluster to be deleted at the same time as the cluster"
  default = true
}


variable "namespace" {
  type = string
  description = "Namespace to host the deployed K8s resources"
  default = "cli-tool"
}

variable "registry_server" {
  type = string
  description = "Container image registry region"
  default = "us.icr.io"
}

variable "registry_username" {
  type = string
  description = "User name for registry"
  default = "iamapikey"
}

variable "ibmcloud_api_key" {}

variable "login_key" {}

variable "staging_key" {}

variable "registry_key" {}

variable "slack_webhook_url" {}
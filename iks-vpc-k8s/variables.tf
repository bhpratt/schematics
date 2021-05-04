
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

variable "delete_storage" {
  default = true
}

variable "ibmcloud_api_key" {}

variable "namespace" {
  default = "cli-tool"
}

variable "login_key" {}

variable "staging_key" {}

variable "registry_key" {}

variable "slack_webhook_url" {}

variable "registry_server" {
  default = "us.icr.io"
}

variable "registry_username" {
  default = "iamapikey"
}
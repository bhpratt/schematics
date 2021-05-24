
variable "region" {
  type = string
  default = "us-east"
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
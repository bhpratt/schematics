### Global variables

variable "ibmcloud_api_key" {}

variable "resource_group" {
  type        = string
  default     = "default"
}

### VPC variables

variable "vpc_name" {
  type        = string
  default     = "satellite-vpc"
}

variable "classic_access" {
  type        = string
  default     = "false"
}

//source: https://cloud.ibm.com/docs/satellite?topic=satellite-sat-regions
variable "region" {
  description = "Region to deploy VPC and Satellite location to"
  type        = string
  default     = "br-sao"

  validation {
  condition = (
      contains(["au-syd", "br-sao", "ca-tor", "eu-de", "eu-gb", "jp-osa", "jp-tok", "us-east", "us-south"], var.region) 
  )
  error_message = "Must choose a valid IBM Cloud region"
  }
}

### Jumpbox variables

variable "my_ip" {
  description = "IP that is allowed access to the VPC jumpbox"
  default     = null
}

variable "my_work_ip" {
  description = "Secondary IP that is allowed access to the VPC jumpbox"
  default     = null
}

variable "my_extra_ip" {
  description = "Tertiary IP that is allowed access to the VPC jumpbox"
  default     = null
}

//ic is images
variable "jumpbox_image_name" {
  type        = string
  default     = "ibm-centos-7-9-minimal-amd64-9"
}

variable "jumpbox_floating_ip_name" {
  type        = string
  default     = "jumpbox-ip"
}

variable "jumpbox_name" {
  type        = string
  default     = "jumpbox-vpc"
}

variable "jumpbox_profile" {
  type        = string
  default     = "bx2-2x8"
}

variable "jumpbox_ssh_key" {
  type        = string
  default     = null
}

### Startup script variables

variable "login_account_id" {}

variable "login_username" {}

//version of oc cli to install on jumpbox
variable "openshift_version" {
  type = string
  default = "4.10.0"
}

variable "security_group_name" {
  type = string
  default = "allow-inbound"
}

variable "ssh_key" {}

### Satellite variables

variable "location" {
  description = "Location Name"
  type        = string
  default = "satellite-workshop"
}

variable "coreos_enabled" {
  description = "If location is enabled for CoreOS hosts"
  type        = bool
  default     = true
}

variable "location_bucket" {
  description = "COS bucket name"
  default     = null
}

variable "host_count" {
  description = "The total number of ibm host to create for control plane"
  type        = number
  default     = 6
}

variable "control_host_provider" {
  type = string
  default = null
}

variable "control_coreos_os" {
  description = "Whether the control plane hosts are CoreOS"
  type        = bool
  default     = false
}

variable "control_custom_script" {
  type        = string
  default     = null
}

variable "auto_assign_labels" {
  description  = "Label to add to host assign ato allow nodes to auto assign to cluster"
  type         = string
  default      = "type:assigncluster"
}

variable "auto_assign_labels_cluster" {
  description  = "Labels to add to the default worker pool to allow nodes to auto assign to cluster"
  type         = set(string)
  default      = [
    "type:assigncluster",
  ]
}

variable "host_link_agent_endpoint" {
  description  = "Use Satellite Link to reduce outbound connections to the public internet"
  type         = bool
  default      = false
}

//ic is images
variable "control_image_name" {
  type        = string
  default     = "ibm-redhat-8-8-minimal-amd64-3"
  # default     = "ibm-redhat-8-6-minimal-amd64-4"
}

variable "control_profile" {
  description  = "Profile information of control hosts"
  type         = string
  # default = "cx2d-16x32"
  default      = "bx2d-4x16"
}


### OpenShift cluster variables

variable "cluster_name" {
  type = string
  default = "satellite-vpc"
}

variable "cluster_operating_system" {
  description = "Operating system for the default worker pool"
  type = string
  default = "REDHAT_8_64"
}

variable "worker_host_provider" {
  type = string
  default = null
}

variable "worker_coreos_os" {
  description = "Whether the worker hosts are CoreOS"
  type        = bool
  default     = false
}

variable "worker_custom_script" {
  type = string
  default = null
}

variable "worker_count" {
  description = "The total number of ibm host to create for cluster"
  type        = number
  default     = 3
}

//ic is images
variable "worker_image_name" {
  type        = string
  default     = "ibm-redhat-8-6-minimal-amd64-4"
}

variable "worker_profile" {
  description = "Profile information of workers"
  type = string
  default = "bx2d-4x16"
}

variable "kube_version" {
  type = string
  default = null
}
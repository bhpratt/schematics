### Global variables

variable "ibmcloud_api_key" {}

variable "resource_group" {
  type = string
  default = "default"
}

### VPC variables

variable "vpc_name" {
  type = string
  default = "satellite-vpc"
}

variable "classic_access" {
  type = string
  default = "false"
}

variable "region" {
  type = string
  default = "us-east"
}

### Jumpbox variables

variable "my_ip" {
  description = "IP that is allowed access to the VPC jumpbox"
  default = null
}

variable "my_work_ip" {
  description = "Secondary IP that is allowed access to the VPC jumpbox"
  default = null
}

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

variable "jumpbox_ssh_key" {
  type = string
  default = null
}

### Startup script variables

variable "login_account_id" {}

variable "login_region" {
  type = string
  default = "us-east"
}

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

variable "managed_from" {
  description = "The IBM Cloud region to manage your Satellite location from. Choose a region close to your on-prem data center for better performance."
  type        = string
  default     = "wdc"
}

variable "location_zones" {
  description = "Allocate your hosts across these three zones"
  type        = list(string)
  default     = ["us-east-1", "us-east-2", "us-east-3"]
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
  default     = 3
}

variable "control_image" {
  description = "Operating system image for the control plane hosts"
  type        = string
  //"ibm-redhat-7-9-minimal-amd64-7"
  #  default     = "r014-b7cd149d-626d-4e55-9a40-cef90b3a74fb"
  //coreos
  default = "r014-ccc49740-c0b6-499b-8c76-d7ac9c250fdb"
}

variable "control_profile" {
  description = "Profile information of control hosts"
  type = string
  default = "cx2d-16x32"
}


### OpenShift cluster variables

variable "cluster_name" {
  type = string
  default = "satellite-vpc"
}

variable "worker_host_provider" {
  type = string
  default = "ibm"
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

variable "worker_image" {
  description = "Operating system image for the workers created"
  type        = string
  //"ibm-redhat-7-9-minimal-amd64-7"
  #  default     = "r014-b7cd149d-626d-4e55-9a40-cef90b3a74fb"
   //ibm-redhat-8-6-minimal-amd64-2 
   default     = "r014-0254777a-9175-409b-8f7a-80ff9b350933"
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
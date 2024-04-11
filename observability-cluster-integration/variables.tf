# IBM provider variables
# uncomment if using local terraform
variable "ibmcloud_api_key" {}

# Cluster variables
variable "cluster_id" {
  type        = string
  default     = null
  description = "ID of the cluster to deploy observability agents to."
}

variable "cluster_region" {
  type        = string
  default     = "us-east"
  description = "The region of the cluster."
}

variable "cluster_resource_group" {
  type        = string
  default     = "default"
  description = "The resource group of the cluster."
}

# Observability variables
variable "monitoring_key" {
  type        = string
  default     = null
  description = "Ingestion key for the monitoring instance."
}

variable "monitoring_region" {
  type        = string
  default     = "us-east"
  description = "Monitoring instance region."
}

variable "logging_key" {
  type        = string
  default     = null
  description = "Ingestion key for the logging instance"
}

variable "logging_region" {
  type        = string
  default     = "us-south"
  description = "Logging instance region."
}
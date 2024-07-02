data "ibm_container_cluster_config" "cluster_config" {
  # update this value with the Id of the cluster where these agents will be provisioned
  cluster_name_id = var.cluster_id
}


# Name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.cluster_resource_group
}

##############################################################################
# Observability Agents
##############################################################################


module "observability_agents" {
  source                        = "terraform-ibm-modules/observability-agents/ibm"
  version                       = "1.27.0"
  is_vpc                        = false
  cluster_id                    = var.cluster_id
  cluster_resource_group_id     = data.ibm_resource_group.resource_group.id
  log_analysis_instance_region  = var.logging_region
  log_analysis_ingestion_key    = var.logging_key
  cloud_monitoring_access_key   = var.monitoring_key
  cloud_monitoring_instance_region = var.monitoring_region
  log_analysis_add_cluster_name = true
}
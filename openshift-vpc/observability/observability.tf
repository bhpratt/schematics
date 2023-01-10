resource "ibm_resource_instance" "logdna_instance" {

  name              = "test"
  service           = "logdna"
  resource_group_id = var.resource_group
  location          = var.region
  plan              = "7-day"

}

output "logdna_instance_id" {
  value = ibm_resource_instance.logdna_instance.id
}

output "logdna_instance_guid" {
  value = ibm_resource_instance.logdna_instance.guid
}


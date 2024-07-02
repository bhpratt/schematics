//Names of the zones for the Satellite location. These zones mirror VPC regions
locals {
  location_zones = ["${var.region}-1", "${var.region}-2", "${var.region}-3"]
}

//maps IBM Cloud regions to Satellite locations. Source: https://cloud.ibm.com/docs/satellite?topic=satellite-sat-regions
locals{
  au-syd   = var.region == "au-syd"   ? "syd" : ""
  br-sao   = var.region == "br-sao"   ? "sao" : ""
  ca-tor 	 = var.region == "ca-tor"   ? "tor" : ""
  eu-de    = var.region == "eu-de"    ? "fra" : ""
  eu-es    = var.region == "eu-es"    ? "mad" : ""
  eu-gb    = var.region == "eu-gb"    ? "lon" : ""
  jp-osa   = var.region == "jp-osa"   ? "osa" : ""
  jp-tok   = var.region == "jp-tok"   ? "tok" : ""
  us-south = var.region == "us-south" ? "dal" : ""
  us-east  = var.region == "us-east"  ? "wdc" : ""

  managed_from = coalesce(local.us-south, local.us-east, local.ca-tor, local.au-syd, local.br-sao, local.eu-de, local.eu-gb, local.jp-osa, local.jp-tok)
}

# name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

 resource "random_string" "id" {
  length = 4
  special = false
  upper = false
}

# name of VPC
resource "ibm_is_vpc" "vpc1" {
  name = "${var.vpc_name}-${random_string.id.result}"
  # Only one VPC per region can have classic access
  classic_access = var.classic_access
  resource_group = data.ibm_resource_group.resource_group.id
}

# VPC subnets. Uses default CIDR range
resource "ibm_is_subnet" "subnet1" {
  name                     = "${var.region}-1"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway_subnet1.id
  resource_group = data.ibm_resource_group.resource_group.id
}

# Include public gateway for connectivity outside of VPC
# To remove public gateway, cancel out this block and line in subnet1
resource "ibm_is_public_gateway" "gateway_subnet1" {
  name       = "satellite-vpc-gateway-${random_string.id.result}"
  vpc        = ibm_is_vpc.vpc1.id
  zone       = "${var.region}-1"
  resource_group = data.ibm_resource_group.resource_group.id

  //User can configure timeouts
  timeouts {
     create = "90m"
  }
 }

resource "ibm_is_security_group" "group" {
  name = "${var.security_group_name}-${random_string.id.result}"
  vpc  = ibm_is_vpc.vpc1.id
}

//only allow a specified source IP
resource "ibm_is_security_group_rule" "rule1" {
  group      = ibm_is_security_group.group.id
  direction  = "inbound"
  remote     = var.my_ip
  depends_on = [ibm_is_security_group.group]
}

resource "ibm_is_security_group_rule" "rule2" {
  group      = ibm_is_security_group.group.id
  direction  = "inbound"
  remote     = var.my_work_ip
  depends_on = [ibm_is_security_group.group]
}

resource "ibm_is_security_group_rule" "rule3" {
  group      = ibm_is_security_group.group.id
  direction  = "inbound"
  remote     = var.my_extra_ip
  depends_on = [ibm_is_security_group.group]
}

//allow all outbound
resource "ibm_is_security_group_rule" "rule4" {
  group      = ibm_is_security_group.group.id
  direction  = "outbound"
  depends_on = [ibm_is_security_group_rule.rule1]
}

//image being used for the jumpbox
data "ibm_is_image" "jumpbox" {
  # name = "centos-7.x-amd64"
  name = var.jumpbox_image_name
}

resource "ibm_is_instance" "jumpbox" {
  name    = "${var.jumpbox_name}-${random_string.id.result}"
  image   = data.ibm_is_image.jumpbox.id
  # image = var.jumpbox_image
  profile = var.jumpbox_profile
  resource_group = data.ibm_resource_group.resource_group.id

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
    security_groups = [ibm_is_security_group.group.id]
  }

  vpc  = ibm_is_vpc.vpc1.id
  zone = "${var.region}-1"
  keys = [var.ssh_key]
  user_data = templatefile("./jumpbox_config.sh", {
    API_KEY           = var.ibmcloud_api_key
    LOGIN_ACCOUNT     = var.login_account_id
    LOGIN_USERNAME    = var.login_username
    LOGIN_REGION      = var.region
    OPENSHIFT_VERSION = var.openshift_version
    SSH_KEY           = (trimspace(var.jumpbox_ssh_key))
    })
  depends_on = [ibm_is_security_group_rule.rule2]
}

resource "ibm_is_floating_ip" "floating_ip" {
  name   = "${var.jumpbox_floating_ip_name}-${random_string.id.result}"
  target = ibm_is_instance.jumpbox.primary_network_interface[0].id
}

output "instance_ip_addr" {
  value = ibm_is_floating_ip.floating_ip.address
}

resource "ibm_satellite_location" "location" {
  location          = "${var.location}-${random_string.id.result}"
  coreos_enabled    = var.coreos_enabled
  managed_from      = local.managed_from
  zones             = local.location_zones
  resource_group_id = data.ibm_resource_group.resource_group.id

  cos_config {
    bucket = var.location_bucket != null ? var.location_bucket : null
  }

  timeouts {
    create = "45m"
  }

}

//image being used for the worker nodes
data "ibm_is_image" "control" {
  name = var.control_image_name
}

resource "ibm_is_instance" "ibm_host" {
  count = var.host_count

  name           = "control-${random_string.id.result}-${count.index + 1}"
  vpc            = ibm_is_vpc.vpc1.id
  zone           = "${var.region}-1"
  keys           = [var.ssh_key]
  image          = data.ibm_is_image.control.id
  profile        = var.control_profile
  resource_group = data.ibm_resource_group.resource_group.id
  user_data      = data.ibm_satellite_attach_host_script.control_script.host_script

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
  }

  #this block will ignore any changes on existing hosts to the attach script
  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}

data "ibm_satellite_attach_host_script" "control_script" {
  location      = ibm_satellite_location.location.id
  coreos_host   = var.control_coreos_os
  custom_script = var.control_custom_script
  host_provider = var.control_host_provider
  # host_link_agent_endpoint = "c-01-ws.br-sao.link.satellite.cloud.ibm.com"
  # host_link_agent_endpoint = var.host_link_agent_endpoint == true ? "c-01-ws.us-east.link.satellite.cloud.ibm.com" : null
  host_link_agent_endpoint = var.host_link_agent_endpoint == true ? "c-01-ws.${var.region}.link.satellite.cloud.ibm.com" : null
}

data "ibm_satellite_attach_host_script" "worker_script" {
  location      = ibm_satellite_location.location.id
  coreos_host   = var.worker_coreos_os
  custom_script = var.worker_custom_script
  host_provider = var.worker_host_provider
  labels        = [var.auto_assign_labels]
  # host_link_agent_endpoint = "c-01-ws.br-sao.link.satellite.cloud.ibm.com"
  host_link_agent_endpoint = var.host_link_agent_endpoint == true ? "c-01-ws.${var.region}.link.satellite.cloud.ibm.com" : null

}

//assign one host first to the control plane to allow creation of new default worker pool
resource "ibm_satellite_host" "assign_host_first" {
  location      = ibm_satellite_location.location.id
  host_id       = "control-${random_string.id.result}-1"
  zone          = "${var.region}-1"
  host_provider = "ibm"
  depends_on     = [ibm_is_instance.ibm_host]
}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [ibm_is_instance.ibm_host]

  create_duration = "120s"
}

//once race condition is fixed, use this stanza to assign all 3 hosts
# resource "ibm_satellite_host" "assign_host" {
#   count = var.host_count

#   location      = ibm_satellite_location.location.id
#   host_id       = "control-${count.index}"
#   zone          = element(var.location_zones, count.index)
#   host_provider = "ibm"
#   depends_on     = [time_sleep.wait_30_seconds]
# }

resource "ibm_satellite_host" "assign_host_second" {
  location      = ibm_satellite_location.location.id
  host_id       = "control-${random_string.id.result}-2"
  zone          = "${var.region}-2"
  host_provider = "ibm"
  depends_on     = [time_sleep.wait_120_seconds]
}

resource "ibm_satellite_host" "assign_host_third" {
  location      = ibm_satellite_location.location.id
  host_id       = "control-${random_string.id.result}-3"
  zone          = "${var.region}-3"
  host_provider = "ibm"
  depends_on     = [time_sleep.wait_120_seconds]
}

resource "ibm_satellite_host" "assign_host_fourth" {
  location      = ibm_satellite_location.location.id
  host_id       = "control-${random_string.id.result}-4"
  zone          = "${var.region}-1"
  host_provider = "ibm"
  depends_on     = [time_sleep.wait_120_seconds]
}

resource "ibm_satellite_host" "assign_host_fifth" {
  location      = ibm_satellite_location.location.id
  host_id       = "control-${random_string.id.result}-5"
  zone          = "${var.region}-2"
  host_provider = "ibm"
  depends_on     = [time_sleep.wait_120_seconds]
}

resource "ibm_satellite_host" "assign_host_sixth" {
  location      = ibm_satellite_location.location.id
  host_id       = "control-${random_string.id.result}-6"
  zone          = "${var.region}-3"
  host_provider = "ibm"
  depends_on     = [time_sleep.wait_120_seconds]
}

//add this rule to the default security group
resource "ibm_is_security_group_rule" "allow_jumpbox" {
  group      = ibm_is_vpc.vpc1.default_security_group
  direction  = "inbound"
  remote     = ibm_is_security_group.group.id
  depends_on = [ibm_is_security_group.group]
}

//image being used for the worker nodes
data "ibm_is_image" "worker" {
  name = var.worker_image_name
}

resource "ibm_is_instance" "ibm_worker" {
  count = var.worker_count

  name           = "worker-${random_string.id.result}-${count.index + 1}"
  vpc            = ibm_is_vpc.vpc1.id
  zone           = "${var.region}-1"
  keys           = [var.ssh_key]
  image          = data.ibm_is_image.worker.id
  profile        = var.worker_profile
  resource_group = data.ibm_resource_group.resource_group.id
  user_data      = data.ibm_satellite_attach_host_script.worker_script.host_script


  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
  }

  #this block will ignore any changes on existing hosts to the attach script
  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}

//temp section to add rhel hosts in addition to rhcos hosts
//image being used for the worker nodes
# data "ibm_satellite_attach_host_script" "worker_script_rhel" {
#   location      = ibm_satellite_location.location.id
#   coreos_host   = false
#   custom_script = var.worker_custom_script_rhel
#   host_provider = null
#   labels        = [var.auto_assign_labels]
#   # host_link_agent_endpoint = "c-01-ws.br-sao.link.satellite.cloud.ibm.com"
#   host_link_agent_endpoint = var.host_link_agent_endpoint == true ? "c-01-ws.${var.region}.link.satellite.cloud.ibm.com" : null

# }

# data "ibm_is_image" "worker_rhel" {
#   name = "ibm-redhat-8-8-minimal-amd64-3"
# }

# resource "ibm_is_instance" "ibm_worker_rhel" {
#   count = var.worker_count

#   name           = "worker-${random_string.id.result}-${count.index + 4}"
#   vpc            = ibm_is_vpc.vpc1.id
#   zone           = "${var.region}-1"
#   keys           = [var.ssh_key]
#   image          = data.ibm_is_image.worker_rhel.id
#   profile        = var.worker_profile
#   resource_group = data.ibm_resource_group.resource_group.id
#   user_data      = data.ibm_satellite_attach_host_script.worker_script.host_script


#   primary_network_interface {
#     subnet = ibm_is_subnet.subnet1.id
#   }

#   #this block will ignore any changes on existing hosts to the attach script
#   lifecycle {
#     ignore_changes = [
#       user_data,
#     ]
#   }
# }
//end temp section

# get the list of available cluster versions in IBM Cloud
data "ibm_container_cluster_versions" "cluster_versions" {
}

//buffer before creating a cluster
resource "time_sleep" "wait_10_minutes" {
  depends_on = [ibm_satellite_host.assign_host_second, ibm_satellite_host.assign_host_third]

  create_duration = "600s"
}

resource "ibm_satellite_cluster" "cluster" {
    name                   = "${var.cluster_name}-${random_string.id.result}"
    location               = ibm_satellite_location.location.id
    enable_config_admin    = true
    kube_version           = (var.kube_version != null ? var.kube_version : "${data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions[3]}_openshift")
    resource_group_id      = data.ibm_resource_group.resource_group.id
    operating_system       = var.cluster_operating_system
    wait_for_worker_update = true
    host_labels            = var.auto_assign_labels_cluster
    worker_count           = 1

    dynamic "zones" {
        for_each = local.location_zones
        content {
            id  = zones.value
        }
    }

    depends_on = [time_sleep.wait_10_minutes]

      timeouts {
    create = "60m"
  }
}

//this terraform template uses auto-assign of worker nodes via labels. uncomment if using manual assign.
# resource "ibm_satellite_host" "assign_host_workers" {
#   count = var.worker_count

#   location      = ibm_satellite_location.location.id
#   cluster       = ibm_satellite_cluster.cluster.id
#   host_id       = "worker-${random_string.id.result}-${count.index + 1}"
#   zone          = element(var.location_zones, count.index)
#   host_provider = "ibm"
# }

	# resource "ibm_satellite_cluster_worker_pool" "create_wp" {
	# 	name               = "auto_assign_wp"  
	# 	cluster            = ibm_satellite_cluster.cluster.id
	# 	worker_count       = 0
	# 	# host_labels        = [var.auto_assign_labels]
	# 	operating_system   = var.cluster_operating_system
	# 	dynamic "zones" {
	# 		for_each = var.location_zones
	# 		content {
	# 			id	= zones.value
	# 		}
	# 	}
	# }

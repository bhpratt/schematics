# name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# name of VPC
resource "ibm_is_vpc" "vpc1" {
  name = var.vpc_name
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
  name       = "satellite-vpc-gateway"
  vpc        = ibm_is_vpc.vpc1.id
  zone       = "${var.region}-1"
  resource_group = data.ibm_resource_group.resource_group.id

  //User can configure timeouts
  timeouts {
     create = "90m"
  }
 }

resource "ibm_is_security_group" "group" {
  name = var.security_group_name
  vpc  = ibm_is_vpc.vpc1.id
}

//only allow a specified source IP
resource "ibm_is_security_group_rule" "rule1" {
  group      = ibm_is_security_group.group.id
  direction  = "inbound"
  remote     = var.my_ip
  depends_on = [ibm_is_security_group.group]
}

//allow all outbound
resource "ibm_is_security_group_rule" "rule2" {
  group      = ibm_is_security_group.group.id
  direction  = "outbound"
  depends_on = [ibm_is_security_group_rule.rule1]
}

resource "ibm_is_instance" "jumpbox" {
  name    = var.jumpbox_name
  image   = var.jumpbox_image
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
    API_KEY = var.ibmcloud_api_key
    LOGIN_ACCOUNT = var.login_account_id
    LOGIN_USERNAME = var.login_username
    LOGIN_REGION = var.login_region
    OPENSHIFT_VERSION = var.openshift_version
    })
  depends_on = [ibm_is_security_group_rule.rule2]
}

resource "ibm_is_floating_ip" "floating_ip" {
  name   = var.jumpbox_floating_ip_name
  target = ibm_is_instance.jumpbox.primary_network_interface[0].id
}

output "instance_ip_addr" {
  value = ibm_is_floating_ip.floating_ip.address
}

resource "ibm_satellite_location" "location" {
  location          = var.location
  coreos_enabled    = var.coreos_enabled
  managed_from      = var.managed_from
  zones             = var.location_zones
  resource_group_id = data.ibm_resource_group.resource_group.id

  cos_config {
    bucket = var.location_bucket != null ? var.location_bucket : null
  }

  depends_on = [ibm_is_vpc.vpc1]
}

resource "ibm_is_instance" "ibm_host" {
  count = var.host_count

  depends_on     = [ibm_satellite_location.location]
  name           = "control-${count.index + 1}"
  vpc            = ibm_is_vpc.vpc1.id
  zone           = "${var.region}-1"
  keys           = [var.ssh_key]
  image          = var.worker_image
  profile        = var.control_profile
  resource_group = data.ibm_resource_group.resource_group.id
  user_data      = data.ibm_satellite_attach_host_script.script.host_script

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
  }
}

data "ibm_satellite_attach_host_script" "script" {
  location      = ibm_satellite_location.location.id
  host_provider = "ibm"
}

//assign one host first to allow creation of new default worker pool
resource "ibm_satellite_host" "assign_host_first" {
  location      = var.location
  host_id       = "control-1"
  zone          = "us-east-1"
  host_provider = "ibm"
  depends_on     = [ibm_is_instance.ibm_host]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [ibm_is_instance.ibm_host]

  create_duration = "60s"
}

//once race condition is fixed, use this stanza to assign all 3 hosts
# resource "ibm_satellite_host" "assign_host" {
#   count = var.host_count

#   location      = var.location
#   host_id       = "control-${count.index}"
#   zone          = element(var.location_zones, count.index)
#   host_provider = "ibm"
#   depends_on     = [time_sleep.wait_30_seconds]
# }

resource "ibm_satellite_host" "assign_host_second" {
  location      = var.location
  host_id       = "control-2"
  zone          = "us-east-2"
  host_provider = "ibm"
  depends_on     = [ibm_satellite_host.assign_host_first]
}

resource "ibm_satellite_host" "assign_host_third" {
  location      = var.location
  host_id       = "control-3"
  zone          = "us-east-3"
  host_provider = "ibm"
  depends_on     = [ibm_satellite_host.assign_host_first]
}

//add this rule to the default security group
resource "ibm_is_security_group_rule" "allow_jumpbox" {
  group      = ibm_is_vpc.vpc1.default_security_group
  direction  = "inbound"
  remote     = ibm_is_security_group.group.id
  depends_on = [ibm_is_security_group.group]
}

resource "ibm_is_instance" "ibm_worker" {
  count = var.worker_count

  depends_on     = [ibm_satellite_location.location]
  name           = "worker-${count.index + 1}"
  vpc            = ibm_is_vpc.vpc1.id
  zone           = "${var.region}-1"
  keys           = [var.ssh_key]
  image          = var.worker_image
  profile        = var.control_profile
  resource_group = data.ibm_resource_group.resource_group.id
  user_data      = data.ibm_satellite_attach_host_script.script.host_script

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
  }
}

# get the list of available cluster versions in IBM Cloud
data "ibm_container_cluster_versions" "cluster_versions" {
}

//buffer before creating a cluster
resource "time_sleep" "wait_10_minutes" {
  depends_on = [ibm_satellite_host.assign_host_second, ibm_satellite_host.assign_host_third]

  create_duration = "600s"
}

resource "ibm_satellite_cluster" "cluster" {
    name                   = "cluster"  
    location               = var.location
    enable_config_admin    = true
    kube_version           = (var.kube_version != null ? var.kube_version : "${data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions[3]}_openshift")
    resource_group_id      = data.ibm_resource_group.resource_group.id
    wait_for_worker_update = true
    dynamic "zones" {
        for_each = var.location_zones
        content {
            id  = zones.value
        }
    }
    depends_on = [time_sleep.wait_10_minutes]
    default_worker_pool_labels = {"cpu" = "8"}
}

resource "ibm_satellite_host" "assign_host_workers" {
  count = var.worker_count

  location      = var.location
  cluster       = ibm_satellite_cluster.cluster.id
  host_id       = "worker-${count.index + 1}"
  zone          = element(var.location_zones, count.index)
  host_provider = "ibm"
  depends_on = [time_sleep.wait_10_minutes]
}

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

resource "ibm_is_security_group" "group" {
  name = var.security_group_name
  vpc  = var.vpc_name
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

  primary_network_interface {
    subnet = "0757-b7efcefc-2de3-428f-81f4-e5ceb0d09d95"
    security_groups = [ibm_is_security_group.group.id]
  }

  vpc  = var.vpc_name
  zone = "us-east-1"
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

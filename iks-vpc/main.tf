# name of VPC
resource "ibm_is_vpc" "vpc1" {
  name = var.vpc_name
  # Only one VPC per region can have classic access
  classic_access = var.classic_access
  resource_group = local.rg_id
}

# remove this after testing
locals {
  enable_private_alb = true
  enable_public_alb = true
  rg_id = data.ibm_resource_group.resource_group.id
}

# name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# VPC subnets. Uses default CIDR range
resource "ibm_is_subnet" "subnet1" {
  name                     = "${var.region}-1"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway_subnet1.id
  resource_group = local.rg_id
}

# Uncomment to add additional subnets
# resource "ibm_is_subnet" "subnet2" {
#   name                     = "${var.region}-2"
#   vpc                      = ibm_is_vpc.vpc1.id
#   zone                     = "${var.region}-2"
#   total_ipv4_address_count = 256
#   resource_group = local.rg_id
# }

# resource "ibm_is_subnet" "subnet3" {
#   name                     = "${var.region}-3"
#   vpc                      = ibm_is_vpc.vpc1.id
#   zone                     = "${var.region}-3"
#   total_ipv4_address_count = 256
#   resource_group = local.rg_id
# }

# Include public gateway for connectivity outside of VPC
# To remove public gateway, cancel out this block and line in subnet1
resource "ibm_is_public_gateway" "gateway_subnet1" {
  name       = "vpcgen2-iks-gateway"
  vpc        = ibm_is_vpc.vpc1.id
  zone       = "${var.region}-1"
  resource_group = local.rg_id

  //User can configure timeouts
  timeouts {
     create = "90m"
  }
 }
 
# IKS cluster. Single zone.
resource "ibm_container_vpc_cluster" "cluster" {
  name                 = var.name
  vpc_id               = ibm_is_vpc.vpc1.id
  flavor               = var.flavor
  kube_version         = (var.kube_version != null ? var.kube_version : null)
  patch_version        = (var.patch_version != null ? var.patch_version : null)
  update_all_workers   = var.update_all_workers
  worker_count         = var.worker_count
  resource_group_id    = data.ibm_resource_group.resource_group.id
  force_delete_storage = var.delete_storage
  # operating_system     = "UBUNTU_18_64"
  # Lets Schematics/Terraform start working with the cluster as soon as a node is available
  wait_till            = "OneWorkerNodeReady"

  zones {
    subnet_id = ibm_is_subnet.subnet1.id
    name      = "${var.region}-1"
  }

    #   lifecycle {
    #     ignore_changes = [
    #         flavor, operating_system, host_pool_id, secondary_storage, worker_count
    #     ]
    # }

  # uncomment to create a multizone cluster
  # zones {
  #   subnet_id = ibm_is_subnet.subnet2.id
  #   name      = "${var.region}-2"
  # }

  # zones {
  #   subnet_id = ibm_is_subnet.subnet3.id
  #   name      = "${var.region}-3"
  # }
}

# uncomment to enable or disable ALBs
# resource "ibm_container_vpc_alb" "alb" {
#   for_each = { for i, v in ibm_container_vpc_cluster.cluster.albs: i => v}
#   alb_id = each.value.id
#   enable = (each.value.alb_type == "private" && local.enable_private_alb) || (each.value.alb_type == "public" && local.enable_public_alb) ? true : false
# }

# 	resource "ibm_container_vpc_worker_pool" "default" {
# 		worker_pool_name       = "default"
# 		cluster                = ibm_container_vpc_cluster.cluster.id
#     vpc_id                 = "r042-84ba361f-78d4-4ec2-b114-0da1bcd9de70"
# 		worker_count           = 3
# 		operating_system       = "UBUNTU_18_64"
#     flavor               = var.flavor

#   zones {
#     subnet_id = ibm_is_subnet.subnet1.id
#     name      = "${var.region}-1"
#   }
#  }

 	# resource "ibm_container_vpc_worker_pool" "default" {
	# 	worker_pool_name       = "test"
	# 	cluster                = ibm_container_vpc_cluster.cluster.id
  #   vpc_id                 = ibm_is_vpc.vpc1.id
	# 	worker_count           = 3
	# 	operating_system       = "UBUNTU_20_64"
  #   flavor               = var.flavor

  # zones {
  #   subnet_id = ibm_is_subnet.subnet1.id
  #   name      = "${var.region}-1"
  # }

    # taints {
    #     key = "upgrade"
    #     value = "ubuntu20"
    #     effect = "NoSchedule"
    # }
#  }
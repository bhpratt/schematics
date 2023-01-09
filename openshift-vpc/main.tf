# COS instance for registry backup
resource "ibm_resource_instance" "cos_instance" {
  name     = var.service_instance_name
  service  = var.service_offering
  plan     = var.plan
  location = "global"
}

# name of VPC
resource "ibm_is_vpc" "vpc1" {
  name = var.vpc_name
}

# name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# get the list of available cluster versions in IBM Cloud
data "ibm_container_cluster_versions" "cluster_versions" {
}
  # Include public gateway for connectivity outside of VPC
 resource "ibm_is_public_gateway" "gateway_subnet1" {
    name       = "vpc-gen2-roks-gateway"
    vpc        = ibm_is_vpc.vpc1.id
    zone       = "${var.region}-1"

    //User can configure timeouts
    timeouts {
        create = "90m"
    }
}

# uncomment to create multizone cluster w/3 public gateways
#  resource "ibm_is_public_gateway" "gateway_subnet2" {
#     name       = "vpc-gen2-roks-gateway-2"
#     vpc        = ibm_is_vpc.vpc1.id
#     zone       = "${var.region}-2"

#     //User can configure timeouts
#     timeouts {
#         create = "90m"
#     }
# }

#  resource "ibm_is_public_gateway" "gateway_subnet3" {
#     name       = "vpc-gen2-roks-gateway-3"
#     vpc        = ibm_is_vpc.vpc1.id
#     zone       = "${var.region}-3"

#     //User can configure timeouts
#     timeouts {
#         create = "90m"
#     }
# }

# VPC subnets. Uses default CIDR range
resource "ibm_is_subnet" "subnet1" {
  name                     = "${var.region}-1"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway_subnet1.id

}

# uncomment to create multizone cluster
# resource "ibm_is_subnet" "subnet2" {
#   name                     = "${var.region}-2"
#   vpc                      = ibm_is_vpc.vpc1.id
#   zone                     = "${var.region}-2"
#   total_ipv4_address_count = 256
#   public_gateway           = ibm_is_public_gateway.gateway_subnet2.id
# }

# resource "ibm_is_subnet" "subnet3" {
#   name                     = "${var.region}-3"
#   vpc                      = ibm_is_vpc.vpc1.id
#   zone                     = "${var.region}-3"
#   total_ipv4_address_count = 256
#   public_gateway           = ibm_is_public_gateway.gateway_subnet3.id
# }

# ROKS cluster. Single zone. Kube version by default will take the 3rd in the list of the valid openshift versions given in the output of `ibmcloud oc versions`
resource "ibm_container_vpc_cluster" "cluster" {
  name                            = var.name
  vpc_id                          = ibm_is_vpc.vpc1.id
  flavor                          = var.flavor
  kube_version                    = (var.kube_version != null ? var.kube_version : "${data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions[2]}_openshift")
  worker_count                    = var.worker_count
  disable_public_service_endpoint = var.public_service_endpoint_disabled
  resource_group_id               = data.ibm_resource_group.resource_group.id
  cos_instance_crn                = ibm_resource_instance.cos_instance.id
  wait_till                       = "OneWorkerNodeReady"


  zones {
    subnet_id = ibm_is_subnet.subnet1.id
    name      = "${var.region}-1"
  }

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

resource "ibm_resource_instance" "logdna_instance" {

  name              = "test"
  service           = "logdna"
  resource_group_id = data.ibm_resource_group.resource_group.id
  location          = var.region
  plan              = "7-day"
}

resource "ibm_resource_key" "resourceKey" {
  name                 = "TestKey"
  resource_instance_id = ibm_resource_instance.logdna_instance.id
  role                 = "Manager"
}

resource "ibm_ob_logging" "logging" {
  depends_on           = [ibm_resource_key.resourceKey]
  cluster              = ibm_container_vpc_cluster.cluster.id
  instance_id          = ibm_resource_instance.logdna_instance.guid
  private_endpoint     = true
}
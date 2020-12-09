# specifies gen2 and region for VPC/IKS resources
provider "ibm" {
  generation = 2
  region = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
}

# review this doc: https://cloud.ibm.com/docs/terraform?topic=terraform-container-data-sources#container-cluster-config-sample
provider "kubernetes" {
  config_path = data.ibm_container_cluster_config.clusterConfig.config_file_path
}


# name of VPC
resource "ibm_is_vpc" "vpc1" {
  name = var.vpc_name
  # Only one VPC per region can have classic access
  classic_access = var.classic_access
}

# name of resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# required inbound connectivity for VPC LB traffic to worker nodes
# https://cloud.ibm.com/docs/containers?topic=containers-clusters#clusters_vpcg2
resource "ibm_is_security_group_rule" "security_group_rule_default_tcp" {
    group = ibm_is_vpc.vpc1.default_security_group
    direction = "inbound"
    tcp {
      port_min = 30000
      port_max = 32767
    }
 }

 resource "ibm_is_security_group_rule" "security_group_rule_default_udp" {
    group = ibm_is_vpc.vpc1.default_security_group
    direction = "inbound"
    udp {
      port_min = 30000
      port_max = 32767
    }
 }

 # Include public gateway for connectivity outside of VPC
 resource "ibm_is_public_gateway" "gateway_subnet1" {
    name       = "vpcgen2-iks-gateway"
    vpc        = ibm_is_vpc.vpc1.id
    zone       = "${var.region}-1"

    //User can configure timeouts
    timeouts {
        create = "90m"
    }
}

# VPC subnets. Uses default CIDR range
resource "ibm_is_subnet" "subnet1" {
  name                     = "${var.region}-1"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway_subnet1.id
}

resource "ibm_is_subnet" "subnet2" {
  name                     = "${var.region}-2"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-2"
  total_ipv4_address_count = 256
}

resource "ibm_is_subnet" "subnet3" {
  name                     = "${var.region}-3"
  vpc                      = ibm_is_vpc.vpc1.id
  zone                     = "${var.region}-3"
  total_ipv4_address_count = 256
}

# IKS cluster. Single zone.
resource "ibm_container_vpc_cluster" "cluster" {
  name              = var.name
  vpc_id            = ibm_is_vpc.vpc1.id
  flavor            = var.flavor
  worker_count      = var.worker_count
  resource_group_id = data.ibm_resource_group.resource_group.id
  # Lets Schematics/Terraform start working with the cluster as soon as a node is available
  wait_till         = "OneWorkerNodeReady"

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

data "ibm_container_cluster_config" "clusterConfig" {

  cluster_name_id = ibm_container_vpc_cluster.cluster.name
  config_dir = "/tmp"
  # depends_on = [
  #   ibm_container_cluster.cluster,
  # ]
}

resource "kubernetes_namespace" "newNamespace" {
  metadata {
    name = var.namespace
  }
  # depends_on = [
  #   ibm_container_cluster.cluster,
  # ]
}

resource "kubernetes_secret" "loginSecret" {
  metadata {
    name = "login"
    namespace = var.namespace
  }

  data = {
    "login" = var.login_key
  }
  # depends_on = [
  # ]
}

resource "kubernetes_secret" "stagingSecret" {
  metadata {
    name = "staging"
    namespace = var.namespace
  }

  data = {
    "login-staging" = var.staging_key
  }
}

resource "kubernetes_secret" "ibmcloudCliSecret" {
  metadata {
    name = "ibm-cloud-cli"
    namespace = var.namespace
  }

  data = {
    "apikey" = var.ibmcloud_cli_key
  }
}

resource "kubernetes_secret" "imagePullSecret" {
  metadata {
    name = "cli-tool-pull-secret"
    namespace = var.namespace
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "${var.registry_server}": {
      "auth": "${base64encode("${var.registry_username}:${var.login_key}")}"
    }
  }
}
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_cron_job" "cliTool" {
  metadata {
    name = "cli-tool"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "30 15 * * 1-5"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 5
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            container {
              name    = "cli-tool"
              image   = "us.icr.io/cli-tool/ibmcloud-clis:latest"
              command = ["/bin/sh", "-c", "./build.sh"]
              env {
                name = "API_KEY"
                value = var.ibmcloud_cli_key
              }
              env {
                name = "LOGIN"
                value = var.login_key
              }
              env {
                name = "LOGIN_STAGING"
                value = var.staging_key
              }
              env {
                name = "SLACK_WEBHOOK_URL"
                value = var.slack_webhook_url
              }
            }
            imagePullSecret = "cli-tool-pull-secret"
          }
        }
      }
    }
  }
}
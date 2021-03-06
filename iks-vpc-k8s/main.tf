# specifies gen2 and region for VPC/IKS resources
provider "ibm" {
  generation = 2
  region = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
}

# review this doc: https://cloud.ibm.com/docs/terraform?topic=terraform-container-data-sources#container-cluster-config-sample
provider "kubernetes" {
  # config_path = data.ibm_container_cluster_config.clusterConfig.config_file_path
  # load_config_file       = "false"
  host                   = data.ibm_container_cluster_config.clusterConfig.host
  token                  = data.ibm_container_cluster_config.clusterConfig.token
  cluster_ca_certificate = data.ibm_container_cluster_config.clusterConfig.ca_certificate
}
# review example: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/container_cluster_config

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

# downloads config so Schematics can deploy Kubernetes resources
data "ibm_container_cluster_config" "clusterConfig" {

  cluster_name_id = ibm_container_vpc_cluster.cluster.name
  # config_dir = "/tmp"
}

# create namespace for cronjob
resource "kubernetes_namespace" "newNamespace" {
  metadata {
    name = var.namespace
  }
 depends_on = [data.ibm_container_cluster_config.clusterConfig]
}

# create imagepullsecret for cronjob
resource "kubernetes_secret" "imagePullSecret" {
  depends_on = [kubernetes_namespace.newNamespace]
  metadata {
    name = "cli-tool-pull-secret"
    namespace = var.namespace
  }
  data = {
    ".dockerconfigjson" = templatefile("${path.module}/config.json", { registry-server = "${var.registry_server}", registry-username = "${var.registry_username}", login-key = "${var.registry_key}", auth = "${base64encode("${var.registry_username}:${var.registry_key}")}" })
}

  type = "kubernetes.io/dockerconfigjson"
}

# cluster cronjob deployment
resource "kubernetes_cron_job" "cliTool" {
  depends_on = [kubernetes_namespace.newNamespace]
  metadata {
    name = "cli-tool"
    namespace = "cli-tool"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "0 15 * * 1-5"
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
                #key used by build.sh to log in, build image. changed from ibmcloud_cli_key
                name = "API_KEY"
                value = var.registry_key
              }
              env {
                #key used for gobx login
                name = "LOGIN"
                value = var.login_key
              }
              env {
                #key used for gobx-staging
                name = "LOGIN_STAGING"
                value = var.staging_key
              }
              env {
                name = "SLACK_WEBHOOK_URL"
                value = var.slack_webhook_url
              }
            }
            image_pull_secrets {
              name = "cli-tool-pull-secret"
            }
          }
        }
      }
    }
  }
}
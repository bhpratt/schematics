terraform {
     required_providers {
        ibm = {
           source = "IBM-Cloud/ibm"
           }
      }
  required_version = ">= 0.12"
}


# specifies gen2 and region for VPC/IKS resources
provider "ibm" {
  region = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
}

# downloads config so Schematics can deploy Kubernetes resources
data "ibm_container_cluster_config" "clusterConfig" {

  cluster_name_id = "iks-vpc-k8s"
  # config_dir = "/tmp"
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


# create namespace for cronjob
resource "kubernetes_namespace" "newNamespace" {
  metadata {
    name = var.namespace
  }
 //depends_on = [data.ibm_container_cluster_config.clusterConfig]
}

# create imagepullsecret for cronjob
resource "kubernetes_secret" "imagePullSecret" {
  //depends_on = [kubernetes_namespace.newNamespace]
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
  //depends_on = [kubernetes_namespace.newNamespace]
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
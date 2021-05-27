# downloads config so Schematics can deploy Kubernetes resources
data "ibm_container_cluster_config" "clusterConfig" {

  cluster_name_id = "iks-vpc-k8s"
  # config_dir = "/tmp"
}

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
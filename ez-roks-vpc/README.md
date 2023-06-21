# EZ-ROKS-VPC Cluster

Creates a single-zone VPC Red Hat Openshift on IBM Cloud cluster in Sao Paulo. To be used with Terraform or IBM Cloud Schematics. Allows for a quick build and teardown of an Openshift cluster and VPC environment.

Contains:
- VPC
- Subnet
- Public gateway
- COS bucket
- Single-zone two-node OpenShift cluster

source: [IBM Cloud Terraform provider](https://github.com/IBM-Cloud/terraform-provider-ibm/tree/master/examples/ibm-cluster/roks-on-vpc-gen2)
# IKS VPC cluster

Run a private VPC Kubernetes cluster on IBM Cloud and automatically provision Kubernetes resources. To be used with Terraform or IBM Cloud Schematics. Allows for a quick build and teardown of a Kubernetes and VPC environment.

source: [IBM Cloud Terraform provider](https://github.com/IBM-Cloud/terraform-provider-ibm/tree/master/examples/ibm-cluster/vpc-gen2-cluster)

Wireguard installation: https://github.com/cloud-design-dev/ibmcloud-vpc-wireguard

//ubuntu20
//2x8 machine
//add ssh key
//eth0,
//add floating IP address to machine (create floating IP separately)
//create sg for jumpbox
# IBM Cloud Satellite location with OpenShift cluster

This set of Terraform scripts provisions the following:

1. VPC in IBM Cloud
2. VSI to use as a jumpbox to access hosts in IBM Cloud Satellite
3. Security groups to allow satellite hosts and jumpbox to have network connectivity. Optionally, user can provide IP address(es) to allow external ssh access to the jumpbox.
4. IBM Cloud Satellite location
5. 6 VPC VSIs (3 for location control plane, 3 for OpenShift cluster)
6. OpenShift cluster in Satellite location.


## Commands
terraform init

terraform apply -auto-approve -var-file=input.tfvars
terraform apply -destroy -auto-approve -var-file=input.tfvars 
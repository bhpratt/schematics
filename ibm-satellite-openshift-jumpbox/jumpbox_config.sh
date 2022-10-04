#! /bin/sh

# for debugging tail -f /var/log/messages

cd /tmp

## add useful packages
yum update -y &&\
yum install -y bash-completion

#install IBM CLOUD CLI
echo "Installing IBM Cloud CLI"
curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

echo "Installing Helm 3"
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl &&\

# Update the permissions for and the location of the Kubernetes CLI executable file
chmod +x ./kubectl &&\
mv ./kubectl /usr/local/bin/kubectl

#install oc cli
echo "Installing version ${OPENSHIFT_VERSION} of the OpenShift CLI"
curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OPENSHIFT_VERSION}/openshift-client-linux.tar.gz &&\

#unpack cli
tar -xvf openshift-client-linux.tar.gz &&\

#move executables to bin
mv oc /usr/local/bin/oc

#Install shortcut command for logging into IBM Cloud account
cat <<'EOF' >>gobx
#!/bin/bash

ibmcloud login -a cloud.ibm.com -c ${LOGIN_ACCOUNT} -u ${LOGIN_USERNAME} -r ${LOGIN_REGION} --apikey ${API_KEY}
EOF

chmod +x ./gobx &&\
mv ./gobx /usr/local/bin/gobx

# Add kubectl, ibmcloud, calicoctl alias
echo "adding commands to bashrc"
printf 'kcfg() { \n $(ibmcloud ks cluster config --cluster $1) \n}\n' >> ~/.bashrc &&\
printf 'alias k=kubectl\n' >> ~/.bashrc &&\
printf 'c () {\n calicoctl $@ \n }\n' >> ~/.bashrc &&\
printf 'alias ic=ibmcloud\n' >> ~/.bashrc &&\
printf 'kk () {\n CLUS=$(kubectl config current-context) \n echo $(tput setaf 4)⎈ $(tput sgr0) Currently targetting: $(tput setaf 2)$CLUS $(tput sgr0) \n }\n' >> ~/.bashrc &&\

# move to root so plugins are installed correctly
cd ~/

#create key so user can ssh into satellite hosts
cat <<'EOF' >> ~/.ssh/id_rsa
${SSH_KEY}
EOF

chmod 600 ~/.ssh/id_rsa

#remove last line to get rid of invalid return character
sed -i '$ d' ~/.ssh/id_rsa

echo '-----END OPENSSH PRIVATE KEY-----' >> ~/.ssh/id_rsa

#start ssh agent
eval `ssh-agent -s`

ssh-add

#install all plugins
ibmcloud plugin install -f container-service
ibmcloud plugin install -f container-registry
ibmcloud plugin install -f infrastructure-service

# add in autocomplete for ibmcloud and kubectl
printf '[[ -f /usr/local/ibmcloud/autocomplete/bash_autocomplete ]] && source /usr/local/ibmcloud/autocomplete/bash_autocomplete\n' >> ~/.bashrc
printf 'source /usr/share/bash-completion/bash_completion\n' >> ~/.bashrc
printf 'source <(kubectl completion bash)\n' >> ~/.bashrc
printf 'complete -F __start_kubectl k\n' >> ~/.bashrc

source ~/.bashrc

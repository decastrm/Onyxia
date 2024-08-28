#!/bin/bash

DOMAIN=${1}

KUBECTL_VERSION=v1.30.1
SOPS_VERSION=v3.9.0
TF_VERSION=1.9.5

export DEBIAN_FRONTEND=noninteractive
sudo apt update && sudo apt install -y ssh vim git curl nmap netcat dnsutils ansible python3-pip virtualenv s3cmd yq unzip bash-completion

cat << EOF > ~/.vimrc
silent! source $VIMRUNTIME/defaults.vim
set mouse-=a
set cursorline
set cursorcolumn
set expandtab
set history=100
set tabstop=4
syntax on
EOF

cat << EOF > $HOME/.bash_aliases
alias ll='ls -lrta'
alias la='ls -A'
alias l='ls -la'
alias gs='git status'
alias venv="source $HOME/venv/bin/activate"
alias wk='/usr/bin/watch -n10 kubectl'
alias k=kubectl
complete -o default -F __start_kubectl k
source <(kubectl completion bash)
alias ns='~/.kube/namespace.sh'
EOF

virtualenv -p python3 $HOME/venv
source $HOME/venv/bin/activate

cat << EOF > /tmp/requirements.txt
ansible==7.0.0
coloredlogs==15.0.1
docker==6.0.1
flake8==6.0.0
gitpython==3.1.29
Jinja2==3.1.2
keystoneauth1==5.1.0
mock==4.0.3
munch==2.5.0
pathlib2==2.3.7.post1
pytest==7.2.0
python-cinderclient==7.4.1
python-glanceclient==4.2.0
python-heatclient==3.1.0
python-keystoneclient==5.0.1
python-neutronclient==8.2.0
python-novaclient==18.2.0
python-octaviaclient==3.2.0
python-openstackclient==6.0.0
python-swiftclient==4.1.0
PyYAML==6.0
setuptools==65.6.3
EOF

mkdir -p $HOME/.config/pip

cat <<EOF > $HOME/.config/pip/pip.conf
[global]
index-url = https://nexus.${DOMAIN}/repository/pypi-proxy/simple
cert = /usr/local/share/ca-certificates/minint/cert.2.crt
EOF

pip install -r /tmp/requirements.txt
pip3 install --no-cache-dir pyyaml kubernetes python-gitlab jmespath

# Install Ansible collections
ansible-galaxy collection install community.general kubernetes.core ansible.utils

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Kubectl
curl -Lo /usr/local/bin/kubectl https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
chmod +x /usr/local/bin/kubectl

# Install SOPS
curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64 && \
mv sops-${SOPS_VERSION}.linux.amd64 /usr/local/bin/sops && \
chmod +x /usr/local/bin/sops

# Install Terraform
curl -LO https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
unzip terraform_${TF_VERSION}_linux_amd64.zip && \
rm -f terraform_${TF_VERSION}_linux_amd64.zip LICENSE.txt && \
chmod +x terraform && \
mv terraform /usr/local/bin

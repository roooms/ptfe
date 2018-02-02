#!/bin/bash

# install certbot
apt-get update
apt-get install software-properties-common --yes
add-apt-repository ppa:certbot/certbot --yes
apt-get update
apt-get install certbot --yes

# generate certificate and key
certbot certonly -n -d ${hostname} -m null@null.com --standalone --agree-tos

# create replicated unattended installer config
cat > /etc/replicated.conf <<EOF
{
  "DaemonAuthenticationType": "password",
  "DaemonAuthenticationPassword": "${replicated_pwd}",
  "TlsBootstrapType": "server-path",
  "TlsBootstrapHostname": "${hostname}",
  "TlsBootstrapCert": "/etc/letsencrypt/live/${hostname}/fullchain.pem",
  "TlsBootstrapKey": "/etc/letsencrypt/live/${hostname}/privkey.pem",
  "LogLevel": "debug",
  "BypassPreflightChecks": true
}
EOF

# install replicated
curl https://install.terraform.io/ptfe/beta > /home/ubuntu/install.sh
bash /home/ubuntu/install.sh no-proxy

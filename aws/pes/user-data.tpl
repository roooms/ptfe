#!/bin/bash

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
new_hostname="ptfe-$${instance_id}"

# set the hostname
hostnamectl set-hostname "$${new_hostname}"
echo "127.0.1.1 $${new_hostname}" >> /etc/hosts

# install required packages
apt-get update --fix-missing
apt-get install unzip awscli jq apache2 --yes

# add instance identifier to apache holding page
cat > /var/www/html/index.html <<EOF
$${new_hostname} $${local_ipv4}
EOF

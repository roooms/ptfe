#!/usr/bin/env bash
set -e
#set -x

echo "--> Installing postgres"
sudo apt-get install postgresql postgresql-contrib -y
sudo systemctl stop postgresql

sudo mkdir /opt/postgres
sudo mkdir /opt/postgres/data
sudo chown postgres:postgres /opt/postgres/data
sudo chmod 0700 /opt/postgres/data

echo "listen_addresses = '10.0.0.72'" | sudo tee -a /etc/postgresql/9.5/main/postgresql.conf
echo "data_directory = '/opt/postgres/data'" | sudo tee -a /etc/postgresql/9.5/main/postgresql.conf

sudo -u postgres /usr/lib/postgresql/9.5/bin/initdb -D /opt/postgres/data

sudo systemctl start postgresql

sudo -u postgres createdb vagrant

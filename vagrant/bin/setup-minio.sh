#!/usr/bin/env bash
set -e
#set -x

CONFIG_DIR="/etc/minio.d"
DATA_DIR="/opt/minio"

if [[ ! -f $(which unzip) ]]; then
  echo "--> Installing unzip"
  sudo apt-get install -y unzip
fi

if [[ ! -f $(which jq) ]]; then
  echo "--> Installing jq"
  sudo apt-get install -y jq
fi

echo "--> Installing awscli"
sudo apt-get install awscli -y

echo "--> Downloading minio"
curl -Os https://dl.minio.io/server/minio/release/linux-amd64/minio

echo "--> Installing minio"
chmod +x minio
sudo mv minio /usr/local/bin/minio
sudo chmod 755 /usr/local/bin/minio
sudo mkdir -p ${CONFIG_DIR} && sudo chmod 755 ${CONFIG_DIR}
sudo mkdir -p ${DATA_DIR} && sudo chmod 755 ${DATA_DIR}

echo "--> Installing systemd minio.service"
sudo cp /vagrant/etc/systemd/system/minio.service /etc/systemd/system/minio.service

echo "--> Configuring minio"
sudo cp /vagrant/etc/minio.d/config.json /etc/minio.d/config.json

echo "--> Starting minio"
sudo systemctl enable minio
sudo systemctl start minio

echo "--> Printing minio keys"
echo "Access Key: $(sudo cat /etc/minio.d/config.json | jq -r .credential.accessKey)"
echo "Secret Key: $(sudo cat /etc/minio.d/config.json | jq -r .credential.secretKey)"

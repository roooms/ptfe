#!/usr/bin/env bash
set -e
#set -x

VERSION="${1:-"$(curl -s https://releases.hashicorp.com/vault/ | grep vault | grep -v "rc" | grep -v "beta" | head -1 | cut -d"/" -f 3)"}"
ZIP="${2:-"vault_${VERSION}_linux_amd64.zip"}"
URL="https://releases.hashicorp.com/vault/${VERSION}/${ZIP}"
CONFIG_DIR="/etc/vault.d"
DATA_DIR="/opt/vault"

if [[ ! -f $(which unzip) ]]; then
  echo "--> Installing unzip"
  sudo apt-get install -y unzip
fi

if [[ ! -f $(which jq) ]]; then
  echo "--> Installing jq"
  sudo apt-get install -y jq
fi

if [[ -f /vagrant/zips/${ZIP} ]]; then
  echo "--> Found /vagrant/zips/${ZIP}"
  cp -f /vagrant/zips/${ZIP} /tmp/${ZIP}
else
  echo "--> Downloading vault ${VERSION} to /tmp/${ZIP}"
  pushd /tmp > /dev/null
  if curl -Os ${URL}; then
    echo "--> Downloaded ${ZIP}"
    popd > /dev/null
  else
    echo "--> Unable to download ${ZIP}"
    popd > /dev/null
    exit 1
  fi
fi

echo "--> Installing vault"
sudo unzip -q -o /tmp/${ZIP} -d /usr/local/bin/
sudo chmod 755 /usr/local/bin/vault
sudo mkdir -p ${CONFIG_DIR} && sudo chmod 755 ${CONFIG_DIR}
sudo mkdir -p ${DATA_DIR} && sudo chmod 755 ${DATA_DIR}

echo "--> Installing systemd vault.service"
sudo cp /vagrant/etc/systemd/system/vault.service /etc/systemd/system/vault.service

VAULT_IP="$(hostname -I | awk '{print $2}')"
VAULT_ADDR="http://${VAULT_IP}:8200"

echo "--> Configuring vault"
sed -e "s/{{ vault_ip }}/${VAULT_IP}/g" /vagrant/etc/vault.d/default.hcl | sudo tee /etc/vault.d/default.hcl
echo "export VAULT_ADDR=${VAULT_ADDR}" | sudo tee /etc/profile.d/vault.sh
sudo chmod 644 /etc/profile.d/vault.sh
source /etc/profile.d/vault.sh

echo "--> Starting vault"
sudo systemctl enable vault
sudo systemctl start vault

echo "--> Initialising vault"
vault operator init | tee /tmp/vault.init
COUNTER=1
grep '^Unseal' /tmp/vault.init | awk '{print $4}' | for KEY in $(cat -); do
  echo "${KEY}" | sudo tee /opt/vault/vault-unseal-key-${COUNTER} 
  COUNTER="$((COUNTER + 1))"
done
grep '^Initial' /tmp/vault.init | awk '{print $4}' | sudo tee /opt/vault/vault-root-token
shred /tmp/vault.init

echo "--> Unsealing vault"
cat /opt/vault/vault-unseal-key-1 | xargs vault operator unseal
cat /opt/vault/vault-unseal-key-2 | xargs vault operator unseal
cat /opt/vault/vault-unseal-key-3 | xargs vault operator unseal

#!/bin/bash

# Creates a machine with the below config and include the below VM startup script
# -Machine Type: e2-highmem-2
# -Boot OS: debian-12-bookworm-x86/64
# -Size(GB): 200
# -Network Tags: sapmachine
# -Cloud API access scopes: Allow full access to all Cloud APIs
# VM startup script
# curl https://raw.githubusercontent.com/google-cloud-abap/abap-cloud-trial-2022-gcp/vm_startup_script.sh -o /tmp/vm_startup_script.sh
# chmod 755 /tmp/vm_startup_script.sh
# nohup /tmp/vm_startup_script.sh > /tmp/output.txt &

#Install Docker Engine
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt-get update
sudo apt-get install zip unzip
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Download image and install SAP 1909 Trial
# Pull the docker image
sudo docker pull sapse/abap-cloud-developer-trial

# Start the docker container
sudo docker run \
  --stop-timeout 3600 \
  --name a4h \
  -h vhcala4hci \
  -p 3200:3200 \
  -p 3300:3300 \
  -p 8443:8443 \
  -p 30213:30213 \
  -p 50000:50000 \
  -p 50001:50001 \
  sapse/abap-platform-trial:1909 \
  -skip-limits-check \
  --agree-to-sap-license

#!/bin/bash

# VM startup script
# curl https://raw.githubusercontent.com/google-cloud-abap/abap-cloud-trial-2023-gcp/vm_startup_script.sh -o /tmp/vm_startup_script.sh
# chmod 755 /tmp/vm_startup_script.sh
# nohup /tmp/vm_startup_script.sh > /tmp/output.txt &

# Update the package list
sudo apt-get update -y

# Install required packages
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    zip \
    unzip

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package list again
sudo apt-get update -y

# Install Docker Engine
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

#Download image and install SAP 1909 Trial
# Pull the docker image
sudo docker pull sapse/abap-cloud-developer-trial:2023

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
  sapse/abap-cloud-developer-trial:2023 \
  -skip-limits-check \
  --agree-to-sap-license

#!/bin/bash
# Create directory and download latest transport (v1.11)
mkdir abap_sdk_transport
cd abap_sdk_transport
wget https://storage.googleapis.com/cloudsapdeploy/connectors/abapsdk/abap-sdk-for-google-cloud-1.11.zip

# Unzip the transport files
unzip abap-sdk-for-google-cloud-1.11.zip

# Copy transport files into the Docker container (adjust file names as needed)
sudo docker cp K900457.GM1 a4h:/usr/sap/trans/cofiles/K900457.GM1
sudo docker cp R900457.GM1 a4h:/usr/sap/trans/data/R900457.GM1

# If you also need the OAuth sample transport (optional), repeat for K900458 / R900458

# Set correct permissions
sudo docker exec -it a4h chown a4hadm:sapsys /usr/sap/trans/cofiles/K900457.GM1
sudo docker exec -it a4h chown a4hadm:sapsys /usr/sap/trans/data/R900457.GM1

# Add to buffer and import
sudo docker exec -it a4h runuser -l a4hadm -c 'tp addtobuffer GM1K900457 A4H client=001 pf=/usr/sap/trans/bin/TP_DOMAIN_A4H.PFL'
sudo docker exec -it a4h runuser -l a4hadm -c 'tp pf=/usr/sap/trans/bin/TP_DOMAIN_A4H.PFL import GM1K900457 A4H U128 client=001'

#!/bin/bash

#Get the project number
PROJECT_NAME=$(gcloud config get project)
#Check if project is set
if [[ -z "$PROJECT_NAME" ]]; then
    echo "Project Name is not set. Use gcloud config set project"
    exit 1
fi

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_NAME \
--format="value(projectNumber)")

#Get the compute/zone
ZONE=$(gcloud config get compute/zone)

#Check if zone is set
if [[ -z "$ZONE" ]]; then
    echo "Compute zone is not set. Use gcloud config set compute/zone"
    exit 1.
fi

#Create a firewall rule
gcloud compute firewall-rules create sapmachine \
--direction=INGRESS --priority=1000 --network=default --action=ALLOW \
--rules=tcp:3200,tcp:3300,tcp:8443,tcp:30213,tcp:50000,tcp:50001 \
--source-ranges=0.0.0.0/0 --target-tags=sapmachine

#Enable Google Service to be accessed by ABAP SDK 
gcloud services enable iamcredentials.googleapis.com
gcloud services enable addressvalidation.googleapis.com

#Create Service Account - will be used by ABAP SDK
gcloud iam service-accounts create abap-sdk-dev \
    --description="ABAP SDK Dev Account" \
    --display-name="ABAP SDK Dev Account"

#Create the VM for docker installation
gcloud compute instances create abap-trial-docker \
    --project=$PROJECT_NAME \
    --zone=$ZONE \
    --machine-type=n2-highmem-4 \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=startup-script=curl\ \
https://raw.githubusercontent.com/google-cloud-abap/abap-cloud-trial-2022-gcp/vm_startup_script.sh\ -o\ /tmp/vm_startup_script.sh$'\n'chmod\ 755\ /tmp/vm_startup_script.sh$'\n'nohup\ /tmp/vm_startup_script.sh\ \>\ /tmp/output.txt\ \& \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --tags=sapmachine \
    --create-disk=auto-delete=yes,boot=yes,device-name=abap-trial-docker,image=projects/debian-cloud/global/images/debian-12-bookworm-v20240815,mode=rw,size=200,type=projects/$PROJECT_NAME/zones/$ZONE/diskTypes/pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any
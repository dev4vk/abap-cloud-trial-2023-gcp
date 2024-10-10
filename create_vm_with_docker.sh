#!/bin/bash

# Get the subnet from the user or default to "default"
SUBNET=${1:-default}

# Get the CREATE_FIREWALL attribute or default to "Y" (yes)
CREATE_FIREWALL=${2:-Y}

# Get the CREATE_SA attribute or default to "Y" (yes)
CREATE_SA=${3:-Y}

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

# --- Summary and Confirmation ---
echo "----------------------------------------"
echo "Summary of activities to be performed:"
echo "- Create firewall rule 'sapmachine'"
echo "- Enable required Google Cloud services"
echo "- Create service account 'abap-sdk-dev@$PROJECT_NAME.iam.gserviceaccount.com'"
echo "- Assign necessary IAM roles to the service account"
echo "- Create Compute Engine VM 'abap-trial-docker-2022'"
echo "----------------------------------------"

read -p "Do you want to continue? (y/n) " confirm

echo "Starting the process... please enter to see satus"

if [[ "$confirm" != "y" ]]; then
  echo "Exiting..."
  exit 0
fi

echo "Performing basic checks..."

#Check if zone is set
if [[ -z "$ZONE" ]]; then
    echo "Compute zone is not set. Use gcloud config set compute/zone"
    exit 1
fi

# Function to check if a firewall rule exists
firewall_rule_exists() {
  gcloud compute firewall-rules describe "$1" &> /dev/null
}

# Function to check if a service account exists
service_account_exists() {
  gcloud iam service-accounts describe "$1" &> /dev/null
}

# Check if the firewall rule already exists and exit if it does
if firewall_rule_exists "sapmachine"; then
  echo "Firewall rule 'sapmachine' already exists. Exiting."
  exit 0
fi

# Check if the service account already exists and exit if it does
if service_account_exists "abap-sdk-dev@$PROJECT_NAME.iam.gserviceaccount.com"; then
  echo "Service account 'abap-sdk-dev@$PROJECT_NAME.iam.gserviceaccount.com' already exists. Exiting."
  exit 0
fi

echo "Basic check completed... starting the process..."

# Create a firewall rule only if CREATE_FIREWALL is not "N"
if [[ "$CREATE_FIREWALL" != "N" ]]; then
    gcloud compute firewall-rules create sapmachine \
    --direction=INGRESS --priority=1000 --network=$SUBNET --action=ALLOW \
    --rules=tcp:3200,tcp:3300,tcp:8443,tcp:30213,tcp:50000,tcp:50001 \
    --source-ranges=0.0.0.0/0 --target-tags=sapmachine
    echo "Firewall rule 'sapmachine' created..."
fi

#Enable Google Service to be accessed by ABAP SDK 
gcloud services enable iamcredentials.googleapis.com
gcloud services enable addressvalidation.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable aiplatform.googleapis.com

# Create Service Account only if CREATE_SA is not "N"
if [[ "$CREATE_SA" != "N" ]]; then
    gcloud iam service-accounts create abap-sdk-dev \
        --description="ABAP SDK Dev Account" \
        --display-name="ABAP SDK Dev Account"
fi

gcloud projects add-iam-policy-binding $PROJECT_NAME \
    --member "serviceAccount:abap-sdk-dev@$PROJECT_NAME.iam.gserviceaccount.com" \
    --role "roles/aiplatform.user" \
    --role "roles/storage.objectAdmin" \
    --role "roles/iam.serviceAccountTokenCreator"
echo "Service account created and IAM roles assigned..."

#Create the VM for docker installation
gcloud compute instances create abap-trial-docker-2022 \
    --project=$PROJECT_NAME \
    --zone=$ZONE \
    --machine-type=n2-highmem-4 \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=$SUBNET \
    --metadata=startup-script=curl\ \
https://raw.githubusercontent.com/google-cloud-abap/abap-cloud-trial-2022-gcp/main/vm_startup_script.sh\ -o\ /tmp/vm_startup_script.sh$'\n'chmod\ 755\ /tmp/vm_startup_script.sh$'\n'nohup\ /tmp/vm_startup_script.sh\ \>\ /tmp/output.txt\ \& \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=abap-sdk-dev@$PROJECT_NAME.iam.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --tags=sapmachine \
    --create-disk=auto-delete=yes,boot=yes,device-name=abap-trial-docker,image=projects/debian-cloud/global/images/debian-12-bookworm-v20240815,mode=rw,size=200,type=projects/$PROJECT_NAME/zones/$ZONE/diskTypes/pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

echo "Compute instance abap-trial-docker-2022 created... Please proceed with next steps"

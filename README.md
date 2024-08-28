# Install ABAP Platform Trail 2022 docker on Google Cloud Platform

The scripts listed in this repository is referred by article - Evaluating ABAP SDK for Google Cloud using ABAP Platform Trial 1909 on Google Cloud Platform. 
Below is the Google Bard generated explanation of each of the scripts:  

## Create Virtual Machine
**Script name:** [create_vm_with_docker.sh](https://github.com/google-cloud-abap/community/blob/main/blogs/abap-trial-docker-1909/create_vm_with_docker.sh)

The script creates a Google Cloud Platform (GCP) virtual machine (VM) for installing Docker. The script first gets the project number and zone from the GCP configuration. It then creates a firewall rule to allow traffic on ports 3200, 3300, 8443, 30213, 50000, and 50001 to the VM. It then enables the Google Cloud IAM credentials and address validation services, which are required for ABAP SDK sample code. Next, it creates a service account that will be used by the ABAP SDK. Finally, it creates the VM with the specified configuration.

Here is a more detailed explanation of each step:

-  The script validates if project name a and default compute/zone has been set.
```bash
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
```
-  The script then create a firewall. This line creates a firewall rule to allow traffic on ports 3200, 3300, 8443, 30213, 50000, and 50001 to the VM. The `-e direction=INGRESS` flag specifies that the traffic is coming into the VM. The `-e priority=1000` flag specifies that this rule has a priority of 1000, which means it will be applied before any other firewall rules. The `-e network=default` flag specifies that the rule applies to the default network. The `-e action=ALLOW` flag specifies that the traffic is allowed. The `-e rules=tcp:3200,tcp:3300,tcp:8443,tcp:30213,tcp:50000,tcp:50001` flag specifies the ports that are allowed. The `-e source-ranges=0.0.0.0/0` flag specifies that the traffic can come from any source IP address. The `-e target-tags=sapmachine` flag specifies that the rule applies to the VM with the tag `sapmachine`.
```bash
gcloud compute firewall-rules create sapmachine \ --direction=INGRESS --priority=1000 --network=default --action=ALLOW \ --rules=tcp:3200,tcp:3300,tcp:8443,tcp:30213,tcp:50000,tcp:50001 \ --source-ranges=0.0.0.0/0 --target-tags=sapmachine
```
-  This belo lines enables the Google Cloud IAM credentials service and Address Validation service.. This service is required for the ABAP SDK to code sample provided in the blog.
```bash
gcloud services enable iamcredentials.googleapis.com
gcloud services enable addressvalidation.googleapis.com
```
-  This line creates a service account named `abap-sdk-dev`. This service account will be used by the ABAP SDK.
```bash
gcloud iam service-accounts create abap-sdk-dev \
  --description="ABAP SDK Dev Account" \
  --display-name="ABAP SDK Dev Account"
```
-  The below line create the vm `abap-trail-docker`, with startup script [vm_startup_script.sh](https://github.com/google-cloud-abap/community/blob/main/blogs/abap-trial-docker-1909/vm_startup_script.sh) to install docker and SAP 1909 trail.
```bash
gcloud compute instances create abap-trial-docker \
  --project=abap-sdk-poc \
  --zone=us-west4-b \
  --machine-type=e2-highmem-2 \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --metadata=startup-script=curl\ \ https://raw.githubusercontent.com/google-cloud-abap/community/main/blogs/abap-trial-docker-1909/vm_startup_script.sh\ -o\ /tmp/vm_startup_script.sh'\n'chmod\ 755
```

## Virtual Machine Startup Script
**Script Name:** [vm_startup_script.sh](https://github.com/google-cloud-abap/community/blob/main/blogs/abap-trial-docker-1909/vm_startup_script.sh)

The script is divided into two parts:

1.  Install Docker Engine
    -   The first part of the script installs Docker Engine on the system. This is done by removing any existing Docker packages, updating the apt package index, installing ca-certificates, curl, and gnupg, creating a directory for Docker's GPG key, downloading Docker's GPG key, making the Docker GPG key readable, creating a file to add Docker's repository to apt, and updating the apt package index again.
    -   Once these steps are complete, Docker Engine will be installed on the system.
2.  Download image and install SAP 1909 Trial
    -   The second part of the script downloads the SAP 1909 Trial image and starts a Docker container from the image. This is done by pulling the Docker image, starting the Docker container, and mapping the container's ports to the host's ports.

The following are the specific steps that are performed in the script:

-   The `for` loop removes any existing Docker packages.
-   The `sudo apt-get update` command updates the apt package index.
-   The `sudo apt-get install zip unzip` command installs zip, and unzip.
-   The `sudo apt-get install ca-certificates curl gnupg` command installs ca-certificates, curl, and gnupg.
-   The `sudo install -m 0755 -d /etc/apt/keyrings` command creates a directory for Docker's GPG key.
-   The `curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg` command downloads Docker's GPG key.
-   The `sudo chmod a+r /etc/apt/keyrings/docker.gpg` command makes the Docker GPG key readable.
-   The `echo` command creates a file to add Docker's repository to apt.
-   The `sudo tee /etc/apt/sources.list.d/docker.list > /dev/null` command writes the file to the `/etc/apt/sources.list.d/docker.list` directory.
-   The `sudo apt-get update` command updates the apt package index again.
-   The `sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin` command installs Docker CE, Docker CE CLI, containerd.io, docker-buildx-plugin, and docker-compose-plugin.
-   The `sudo docker pull sapse/abap-platform-trial:1909` command pulls the Docker image.
-   The `sudo docker run` command starts the Docker container and maps the container's ports to the host's ports.

## Import transport for ABAP SDK for Google Cloud
**Script Name:**  [import_abap_sdk.sh](https://github.com/google-cloud-abap/community/blob/main/blogs/abap-trial-docker-1909/import_abap_sdk.sh)

The code first creates a directory called `abap_sdk_transport` and changes to that directory. Then, it downloads the transport files from the Google Cloud Storage bucket.

```bash
mkdir abap_sdk_transport 
cd abap_sdk_transport 
wget https://storage.googleapis.com/cloudsapdeploy/connectors/abapsdk/abap-sdk-for-google-cloud-1.0.zip
```
Next, the code unzips the transport files.

```bash
unzip abap-sdk-for-google-cloud-1.0.zip
```

Finally, the code copies the files to the `trans` folder of the Docker container named `a4h`. It then runs the `tp` command to import the transport.
```bash
sudo docker cp K900191.GM1 a4h:/usr/sap/trans/cofiles/K900191.GM1 
sudo docker cp R900191.GM1 a4h:/usr/sap/trans/data/R900191.GM1
sudo docker exec -it a4h runuser -l a4hadm -c 'tp addtobuffer GM1K900191 A4H client=001 pf=/usr/sap/trans/bin/TP_DOMAIN_A4H.PFL'
sudo docker exec -it a4h runuser -l a4hadm -c 'tp pf=/usr/sap/trans/bin/TP_DOMAIN_A4H.PFL import GM1K900191 A4H U128 client=001'
```

The `tp` command is used to manage transports in SAP systems. The `addtobuffer` option adds the transport to the buffer, and the `import` option imports the transport.

The `client=001` option specifies the client that the transport will be imported into. The `pf=/usr/sap/trans/bin/TP_DOMAIN_A4H.PFL` option specifies the PFL file that will be used to import the transport.
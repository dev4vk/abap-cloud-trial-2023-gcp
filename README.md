# Install ABAP Platform Trail 2022 docker on Google Cloud Platform

The scripts listed in this repository is referred by article - Evaluating ABAP SDK for Google Cloud using ABAP Platform Trial 2022 on Google Cloud Platform. 
Below is the Google Bard generated explanation of each of the scripts:  

```markdown
# ABAP Cloud Trial VM Creation Script
**Script name:** [create_vm_with_docker.sh](https://github.com/google-cloud-abap/abap-cloud-trial-2022-gcp/blob/main/create_vm_with_docker.sh)

This script automates the creation of a Google Cloud Platform (GCP) Virtual Machine (VM) configured for the ABAP Cloud Trial 2022. 

## Prerequisites

* **GCP Project:** You must have an active GCP project.
* **GCP SDK:**  The Google Cloud SDK installed and configured. 
* **Project ID & Zone:** You must have your project ID and compute zone set. Use `gcloud config set project <your-project-id>` and `gcloud config set compute/zone <your-zone>` to configure. 

## Usage

```bash
./create_vm.sh [subnet] [create_firewall] [create_sa]
```

**Parameters:**

* **subnet:** (Optional) The name of the subnet to use for the VM. Default: "default".
* **create_firewall:** (Optional) Whether to create a firewall rule for the VM. Default: "Y" (yes). Set to "N" to skip firewall creation.
* **create_sa:** (Optional) Whether to create a service account for the VM. Default: "Y" (yes). Set to "N" to skip service account creation.

## Script Functionality

1. **Get Project Information:** Retrieves the project ID and project number from GCP configuration.
2. **Get Compute Zone:** Retrieves the compute zone from GCP configuration.
3. **Create Firewall Rule:** (Optional) Creates a firewall rule to allow access to ports used by the ABAP Cloud Trial on the VM. 
4. **Enable Google Services:** Enables the IAM Credentials and Address Validation APIs for the VM.
5. **Create Service Account:** (Optional) Creates a service account for the VM.
6. **Create VM:** Creates a VM instance named "abap-trial-docker-2022" with the following specifications:
   * **Machine Type:** n2-highmem-4
   * **Network:** Specified subnet (or default) with PREMIUM tier and IPV4_ONLY stack type.
   * **Startup Script:** Runs a script to set up the VM for the ABAP Cloud Trial.
   * **Maintenance Policy:** MIGRATE
   * **Provisioning Model:** STANDARD
   * **Service Account:** The project's compute service account.
   * **Scopes:**  `https://www.googleapis.com/auth/cloud-platform`
   * **Tags:** `sapmachine`
   * **Disk:** A 200 GB Persistent Disk with the Debian 12 image.
   * **Shielded VM:** Enabled with VTPM and integrity monitoring.
   * **Labels:** `goog-ec-src=vm_add-gcloud`

## Notes

* The startup script (`vm_startup_script.sh`) is located in the `google-cloud-abap/abap-cloud-trial-2022-gcp/` repository on GitHub. You can find the script and its documentation there.
* This script will create the VM in the specified zone.
* The VM will be created with a specific set of resources and configurations optimized for the ABAP Cloud Trial. 
* For more information on the ABAP Cloud Trial, refer to the official documentation and repository: [https://github.com/google-cloud-abap/abap-cloud-trial-2022-gcp](https://github.com/google-cloud-abap/abap-cloud-trial-2022-gcp)
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
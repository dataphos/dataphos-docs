---
title: "Pulumi"
draft: false
weight: 3
---

## Setting up your environment

### Prerequisites

Publisher's components run in a Kubernetes environment. This quickstart guide will assume that you have
[Python 3](https://www.python.org/downloads/) and [Pulumi](https://www.pulumi.com/docs/install/) tools installed. Pulumi repository can be accessed on the [Pulumi repository](https://github.com/dataphos/dataphos-infra).

This quickstart guide will assume creating new resources instead of importing existing ones into the active stack. If you wish to import your own resources, check [Deployment Customization](/publisher/configuration/pulumi).

### Example source database

Publisher has multiple data source options. This quickstart guide will use a mock Postgres database with mock invoice data as a data ingestion source. The database is deployed as a Kubernetes StatefulSet resource using Pulumi.

The database credentials are defined as environment variables within the container inside the postgres template.

The "invoices" database can be accessed using a database client with "demo_user" as the username and "demo_password" as the password.


### Publisher namespace

The namespace where the components will be deployed is defined in the config file, you don't have to create it yourself. We will use the namespace `dataphos` in this guide. 

```bash
  namespace: dataphos
```

### Download the Publisher Helm charts

The Dataphos Helm charts are located in the [Dataphos Helm Repository](https://github.com/dataphos/dataphos-helm).

To properly reference the Publisher charts, clone the Helm repository and copy the entire `dataphos-publisher` and `dataphos-publisher-webui` directories into the `helm_charts` directory of this repository.

### Install Dependencies

Create a virtual environment from the project root directory and activate it:

```bash
py -m venv venv
./venv/Scripts/activate
```

Install package dependencies:
```bash
py -m pip install -r ./requirements.txt
```

Note: This usually doesn't take long, but can take up to 45 minutes, depending on your setup.

## Publisher deployment

### Cloud provider and stack configuration


{{< tabs "deployment" >}}
{{< tab "GCP-Kafka" >}}
### GCP-Kafka

Deploy all of the required Publisher components for publishing messages to the Kafka topic.

Install the Google Cloud SDK and then authorize access with a user account. Next, Pulumi requires default application credentials to interact with your Google Cloud resources, so run auth application-default login command to obtain those credentials:

```bash
$ gcloud auth application-default login
```

### Configure your stack

You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers. Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a a pre-configured stack template for your stack. 

```bash
$ pulumi stack init publisher-gcp-kafka-dev
```
This will create a new stack named `publisher-gcp-kafka-dev` in your project and set it as the active stack.


## HTTPS setup

Publisher uses HTTPS for two of its components (Web UI and Manager). It requires a predefined static IP address, domain name and certificate for both components inside the GCP project where Publisher is deployed for them to work properly.

**1. Reserve static external IP addresses**

With your working project selected on the GCP Console, navigate to VPC Network → IP addresses and click on the RESERVE EXTERNAL STATIC ADDRESS button in the top header. Create a Global IPv4 address named *publisher-manager-ip*. Repeat this procedure to create another address named *publisher-webui-ip*. Copy these IP addresses to use them in the next step.

Alternatively, run the following gcloud commands in a console window:

```bash
gcloud compute addresses create publisher-manager-ip --project=<project_name> --global
gcloud compute addresses create publisher-webui-ip --project=<project_name> --global
gcloud compute addresses describe publisher-manager-ip --project=<project_name> --global
gcloud compute addresses describe publisher-webui-ip --project=<project_name> --global
```
Replace *<project_name>* with the name of your project.


**2. Create DNS records**

To create DNS records, you need to have a domain registered with a domain provider. If you don’t have a domain, you can register one with a domain registrar, e.g. GoDaddy. 
We will use Cloud DNS to manage DNS records in your domain. If you choose to skip this step, you need to create these records directly in your domain hosting service.

Navigate to Network services → Cloud DNS and create a new public zone or select an existing one in any project. We will use *myzone.com* as the assumed DNS name in the rest of these instructions. Click on the NS type record created with the zone. Copy the four nameserver names, e.g. ns-cloud-x.googledomains.com. Go to your domain registrar and replace your default nameservers with the ones copied from the created Cloud DNS zone. After the change is propagated, all records created in the Cloud DNS zone will be created in the domain registrar.

Click on the ADD RECORD SET button in the Zone details page of the managed zone that you want to add the record to. Create a DNS record with the *publisher-manager* subdomain in the DNS name field, using the Manager IP address you created previously. Repeat this procedure for the *publisher-webui* DNS record using the WebUI IP created in the previous step. Copy the full DNS names for the next step.

Alternatively, run the following gcloud commands in a console window:

```bash
gcloud dns --project=<project_name> record-sets create publisher-manager.myzone.com. --zone="myzone" --type="A" --ttl="300" --rrdatas=<manager_ip>
gcloud dns --project=<project_name> record-sets create publisher-webui.myzone.com. --zone="myzone" --type="A" --ttl="300" --rrdatas=<webui_ip>
```
Replace `<project_name>`, `<manager_ip>`, `<webui_ip>` with the appropriate values and use your own zone and DNS name instead of *myzone*.

**3. Create a Google-managed SSL certificate**

With your working project selected on the GCP Console, navigate to Network services → Load balancing. The default page view doesn’t enable you to edit certificates, so scroll to the bottom of the page and click the “load balancing link components view” to switch the view to display the load balancing resources. Select the CERTIFICATES tab and click on CREATE SSL CERTIFICATE. Create a Google-managed certificate named *publisher-manager-cert* using the Manager DNS name (*publisher-manager.myzone.com*) in the Domain field. Repeat this procedure for the *publisher-webui-cert* using the WebUI DNS name (*publisher-webui.myzone.com*) in the Domain field.

Alternatively, run the following gcloud commands in a console window:

```bash
gcloud beta compute ssl-certificates create publisher-manager-cert --project=<project_name> --global --domains=publisher-manager.myzone.com
gcloud beta compute ssl-certificates create publisher-webui-cert --project=<project_name> --global --domains=publisher-webui.myzone.com
```
Replace `<project_name`> with the name of your project and use the previously created DNS record values for the domain values.

## Authentication and encryption
Select Postgres database credentials (username and password) you wish to use. The password must contain at least nine characters, of which there are two uppercase letters, two lowercase letters, and two numbers.

Generate a 32B Encryption key using a random key generator, or use the default one provided in the deployment file, for messages used by the Worker component (ENC_KEY_1).

Generate a 16B JWT encryption key for secure communication, or use the default one provided in the deployment file (JWT_SECRET).

{{</ tab >}}
{{< tab "GCP-PubSub" >}}

### GCP-PubSub

Deploy all of the required Publisher components for publishing messages to the PubSub topic.

Install the Google Cloud SDK and then authorize access with a user account. Next, Pulumi requires default application credentials to interact with your Google Cloud resources, so run auth application-default login command to obtain those credentials:

```bash
$ gcloud auth application-default login
```

### Configure your stack

You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers.Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a a pre-configured stack template for your stack. 

```bash
$ pulumi stack init publisher-gcp-pubsub-dev
```
This will create a new stack named `publisher-gcp-pubsub-dev` in your project and set it as the active stack.


## HTTPS setup

Publisher uses HTTPS for two of its components (Web UI and Manager). It requires a predefined static IP address, domain name and certificate for both components inside the GCP project where Publisher is deployed for them to work properly.

**1. Reserve static external IP addresses**

With your working project selected on the GCP Console, navigate to VPC Network → IP addresses and click on the RESERVE EXTERNAL STATIC ADDRESS button in the top header. Create a Global IPv4 address named *publisher-manager-ip*. Repeat this procedure to create another address named *publisher-webui-ip*. Copy these IP addresses to use them in the next step.

Alternatively, run the following gcloud commands in a console window:

```bash
gcloud compute addresses create publisher-manager-ip --project=<project_name> --global
gcloud compute addresses create publisher-webui-ip --project=<project_name> --global
gcloud compute addresses describe publisher-manager-ip --project=<project_name> --global
gcloud compute addresses describe publisher-webui-ip --project=<project_name> --global
```
Replace *<project_name>* with the name of your project.


**2. Create DNS records**

To create DNS records, you need to have a domain registered with a domain provider. If you don’t have a domain, you can register one with a domain registrar, e.g. GoDaddy. 
We will use Cloud DNS to manage DNS records in your domain. If you choose to skip this step, you need to create these records directly in your domain hosting service.

Navigate to Network services → Cloud DNS and create a new public zone or select an existing one in any project. We will use *myzone.com* as the assumed DNS name in the rest of these instructions. Click on the NS type record created with the zone. Copy the four nameserver names, e.g. ns-cloud-x.googledomains.com. Go to your domain registrar and replace your default nameservers with the ones copied from the created Cloud DNS zone. After the change is propagated, all records created in the Cloud DNS zone will be created in the domain registrar.

Click on the ADD RECORD SET button in the Zone details page of the managed zone that you want to add the record to. Create a DNS record with the *publisher-manager* subdomain in the DNS name field, using the Manager IP address you created previously. Repeat this procedure for the *publisher-webui* DNS record using the WebUI IP created in the previous step. Copy the full DNS names for the next step.

Alternatively, run the following gcloud commands in a console window:

```bash
gcloud dns --project=<project_name> record-sets create publisher-manager.myzone.com. --zone="myzone" --type="A" --ttl="300" --rrdatas=<manager_ip>
gcloud dns --project=<project_name> record-sets create publisher-webui.myzone.com. --zone="myzone" --type="A" --ttl="300" --rrdatas=<webui_ip>
```
Replace `<project_name>`, `<manager_ip>`, `<webui_ip>` with the appropriate values and use your own zone and DNS name instead of *myzone*.

**3. Create a Google-managed SSL certificate**

With your working project selected on the GCP Console, navigate to Network services → Load balancing. The default page view doesn’t enable you to edit certificates, so scroll to the bottom of the page and click the “load balancing link components view” to switch the view to display the load balancing resources. Select the CERTIFICATES tab and click on CREATE SSL CERTIFICATE. Create a Google-managed certificate named *publisher-manager-cert* using the Manager DNS name (*publisher-manager.myzone.com*) in the Domain field. Repeat this procedure for the *publisher-webui-cert* using the WebUI DNS name (*publisher-webui.myzone.com*) in the Domain field.

Alternatively, run the following gcloud commands in a console window:

```bash
gcloud beta compute ssl-certificates create publisher-manager-cert --project=<project_name> --global --domains=publisher-manager.myzone.com
gcloud beta compute ssl-certificates create publisher-webui-cert --project=<project_name> --global --domains=publisher-webui.myzone.com
```
Replace `<project_name`> with the name of your project and use the previously created DNS record values for the domain values.

## Authentication and encryption
Select Postgres database credentials (username and password) you wish to use. The password must contain at least nine characters, of which there are two uppercase letters, two lowercase letters, and two numbers.

Generate a 32B Encryption key using a random key generator, or use the default one provided in the deployment file, for messages used by the Worker component (ENC_KEY_1).

Generate a 16B JWT encryption key for secure communication, or use the default one provided in the deployment file (JWT_SECRET).

{{</ tab >}}

{{< tab "Azure-Kafka" >}}
### Azure-Kafka

Deploy all of the required Publisher components to the Azure Cloud and publish messages to the Kafka broker.

Log in to the Azure CLI and Pulumi will automatically use your credentials:
```bash
$ az login
```

### Configure your stack
You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers.Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a a pre-configured stack template for your stack. 

```bash
$ pulumi stack init publisher-azure-kafka-dev
```
This will create a new stack named `publisher-azure-kafka-dev` in your project and set it as the active stack.


## HTTPS setup

Publisher uses HTTPS for two of its components (Web UI and Manager). To handle HTTPS, two external components must be deployed to the cluster. One to enable external traffic to the cluster, and the other to ensure the external traffic uses HTTPS protocol. Installation is done using public images.

## Helm

The deployment of required prerequisites is done over Helm. Helm is the package manager for Kubernetes. Helm can be installed using Chocolatey (Windows) and Apt (Debian/Ubuntu). For other operating systems check the official documentation.

On Windows:

```yaml
choco install kubernetes-helm
```

On Debian/Ubuntu:

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

## Nginx Ingress Controller

To manage external traffic to the cluster, an Ingress Controller solution should be provided. We opted for the Nginx Ingress Controller.

Install the Nginx Ingress Controller:

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace ingress-basic --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

Generate TLS key and TLS certificate which will be used in secrets (you can use the use v3.conf file from [here](https://github.com/dataphos/dataphos-docs/tree/main/examples/publisher/v3.conf)).

```bash
openssl req -newkey rsa:2048 -nodes -keyout tls.key -out tls.csr -config v3.conf

openssl x509 -req -in tls.csr -signkey tls.key -out tls.crt -days 365 -extensions v3_req -extfile v3.conf
```


## DNS records

To use the Web UI and Manager components, DNS records need to be created for Ingress Controllers public IP address.

Extract the Ingress Controller public IP address.

```bash
kubectl get services nginx-ingress-ingress-nginx-controller --namespace ingress-basic \
  --output jsonpath='{.status.loadBalancer.ingress[0].ip}'
/
```
On your domain provider, add two A record sets for the extracted IP address, one for the Manager component and one for the Web UI component.

In case your organization does not own a registered domain, we recommend GoDaddy as the domain provider.

## Authentication and encryption

Select Postgres database credentials (username and password) you wish to use. The password must contain at least nine characters, of which there are two uppercase letters, two lowercase letters, and two numbers.

Generate a 32B Encryption key using a random key generator, or use the default one provided in the deployment file, for messages used by the Worker component (ENC_KEY_1).

Generate a 16B JWT encryption key for secure communication, or use the default one provided in the deployment file (JWT_SECRET). 

{{</ tab >}}
{{< tab "Azure-ServiceBus" >}}
### Azure-ServiceBus

Deploy all of the required Publisher components to the Azure Cloud and publish messages to the ServiceBus.

Log in to the Azure CLI and Pulumi will automatically use your credentials:
```bash
$ az login
```

### Configure your stack
You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers.Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a a pre-configured stack template for your stack. 

```bash
$ pulumi stack init publisher-azure-sb-dev
```
This will create a new stack named `publisher-azure-sb-dev` in your project and set it as the active stack.

## HTTPS setup

Publisher uses HTTPS for two of its components (Web UI and Manager). To handle HTTPS, two external components must be deployed to the cluster. One to enable external traffic to the cluster, and the other to ensure the external traffic uses HTTPS protocol. Installation is done using public images.

## Helm

The deployment of required prerequisites is done over Helm. Helm is the package manager for Kubernetes. Helm can be installed using Chocolatey (Windows) and Apt (Debian/Ubuntu). For other operating systems check the official documentation.


On Windows:

```yaml
choco install kubernetes-helm
```

On Debian/Ubuntu:

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

## Nginx Ingress Controller

To manage external traffic to the cluster, an Ingress Controller solution should be provided. We opted for the Nginx Ingress Controller.

Install the Nginx Ingress Controller:

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace ingress-basic --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

Generate TLS key and TLS certificate which will be used in secrets (you can use the use v3.conf file from [here](https://github.com/dataphos/dataphos-docs/tree/master/examples/publisher/v3.conf)).

```bash
openssl req -newkey rsa:2048 -nodes -keyout tls.key -out tls.csr -config v3.conf

openssl x509 -req -in tls.csr -signkey tls.key -out tls.crt -days 365 -extensions v3_req -extfile v3.conf
```


## DNS records

To use the Web UI and Manager components, DNS records need to be created for Ingress Controllers public IP address.

Extract the Ingress Controller public IP address.

```bash
kubectl get services nginx-ingress-ingress-nginx-controller --namespace ingress-basic \
  --output jsonpath='{.status.loadBalancer.ingress[0].ip}'
/
```
On your domain provider, add two A record sets for the extracted IP address, one for the Manager component and one for the Web UI component.

In case your organization does not own a registered domain, we recommend GoDaddy as the domain provider.

## Authentication and encryption

Select the Postgres database credentials (username and password) you wish to use. The password must contain at least nine characters, of which there are two uppercase letters, two lowercase letters, and two numbers.

Generate a 32B Encryption key using a random key generator, or use the default one provided in the deployment file, for messages used by the Worker component (ENC_KEY_1).

Generate a 16B JWT encryption key for secure communication, or use the default one provided in the deployment file (JWT_SECRET). 

{{</ tab >}}
{{</ tabs >}}

### Deployment

Preview and deploy infrastructure changes:
```bash
$ pulumi up
```
Destroy your infrastructure changes:
```bash
$ pulumi destroy
```

## Start the Publisher Web UI

Following the deployment, you can connect to the Publisher via its WebUI.

To login use the admin username `publisher_admin` with the password `Adm!n`.

To start a Publisher instance, Publisher configuration files should be added through the Web CLI.

Access the Web UI by its public IP address and open the Web CLI tab.

To get the Web UI IP address run the following command.

```bash
kubectl get services publisher-webui --namespace dataphos \
  --output jsonpath='{.status.loadBalancer.ingress[0].ip}'
/
```

To access the Web UI, paste the Web UI IP address in your web browser and specify port 8080, e.g. `http://1.1.1.1:8080`.

### Starting a Publisher Instance section

First, the source configuration should be created. The source database will be accessed by its public IP address.

To get the source database IP address run the following command.

```bash
kubectl get services publisher-postgres-source --namespace publisher-source \
  --output jsonpath='{.status.loadBalancer.ingress[0].ip}'
/
```

In the UI, navigate to the **WebCLI** tab and load the following YAML file as a **Source**.

Add the following source configuration for the Publisher to connect to the "invoices" database we created.

```yaml
sourceName: publisher-postgres-source
sourceType: Postgres
host: <LoadBalancer IP address>
port: 5432
databaseName: invoices
username: demo_user
password: demo_password
```

Still within the **WebCLI** tab, load the following YAML file as a **Destination**.

Add the following destination configuration for your Pub/Sub topic. Keys with brackets should be replaced with your values.

```yaml
destinationName: publisher-pubsub-destination
destinationType: PubSub
parameters:
  ProjectID: <your project id>
  TopicID: <your topic>
```

Finally, load the following instance configuration that ingests data from the invoice source, forms business objects according to the definition, and publishes messages to Pub/Sub.

```yaml
publisherName: publisher-demo
sourceName: publisher-postgres-source
destinationName: publisher-pubsub-destination
serializationType: Avro
encryptionEnabled: false
businessObject:
  description: "Demo Publisher - invoices for client"
  objectGroup: "invoices-client"
  additionalMetadata:
    organization: Syntio
  definition:
    - client_info:
        - client_id
        - client_username
        - client_location
    - invoice_info:
        - invoice_id
        - creation_date
        - due_date
        - fully_paid_date
    - invoice_items:
        - invoice_item_id
        - quantity
        - total_cost
  groupElements:
    - client_id
    - invoice_id
  arrayElements:
    - invoice_items
  keyElements:
    - client_id
    - invoice_id
  idElements:
    - client_id
  query: |
    SELECT 
      invoice_id, 
      client_id, 
      client_username, 
      client_location, 
      creation_date, 
      due_date, 
      fully_paid_date, 
      invoice_item_id, 
      quantity, 
      total_cost, 
      billing_item_id
    FROM demo_invoices
    WHERE 
      creation_date >= to_timestamp({{ .FetchFrom }},'YYYY-MM-DD HH24:MI:SS') 
      AND 
      creation_date < to_timestamp({{ .FetchTo }}, 'YYYY-MM-DD HH24:MI:SS');
fetcherConfig:
  fetchingThreadsNO: 3
  queryIncrementType: HOUR
  queryIncrementValue: 12
  initialFetchValue: 2020-01-01 00:20:00.000
  useNativeDriver: true
```

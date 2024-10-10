---
title: "Pulumi"
draft: false
weight: 3
---

## Setting up your environment

### Prerequisites

Schema Registry components run in a Kubernetes environment. This quickstart guide will assume that you have [Python 3](https://www.python.org/downloads/) and [Pulumi](https://www.pulumi.com/docs/install/)  tools installed. Pulumi repository can be accessed on the [Pulumi repository](https://github.com/dataphos/dataphos-infra).
Schema Registry has multiple message broker options. This quickstart guide will assume creating new resources instead of importing existing ones into the active stack. If you wish to import your own resources check [Deployment Customization](/schema_registry/configuration/pulumi).

### Schema Registry namespace

The namespace where the components will be deployed is defined in the config file, you don't have to create it by yourself. We will use the namespace `dataphos` in this guide. 

```bash
  namespace: dataphos
```

### Download the Schema Registry Helm charts

The Dataphos Helm charts are located in the [Dataphos Helm Repository](https://github.com/dataphos/dataphos-helm).

To properly reference the Schema Registry charts, clone the Helm repository and copy the entire `dataphos-schema-registry` and `dataphos-schema-validator` directories into the `helm_charts` directory of this repository.

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

## Deployment

Schema registry is separated into two components: the **registry** component and the **validator** component.

The registry component is used as a central schema management system that provides options of schema registration and
versioning as well as schema validity and compatibility checking. Therefore, it is usually deployed only once.

The validator component acts as a message validation system, meaning that it consists of validators that validate the
message for the given message schema. The validator supports JSON, AVRO, ProtoBuf, XML and CSV message formats. The idea is
to have multiple validator components for every topic you wish to validate the schemas for and therefore the validator
component might be deployed multiple times.

### Cloud provider and stack configuration


{{< tabs "Schema Registry - validator component deployment" >}} 
{{< tab "GCP Pub/Sub" >}}

Deploy all of the required Schema Registry components for publishing messages to the PubSub topic

Install the Google Cloud SDK and then authorize access with a user account. Next, Pulumi requires default application credentials to interact with your Google Cloud resources, so run auth application-default login command to obtain those credentials:

```bash
$ gcloud auth application-default login
```

### Configure your stack

You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers. Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a a pre-configured stack template for your stack. 

```bash
$ pulumi stack init schemaregistry-gcp-pubsub-dev
```
This will create a new stack named `schemaregistry-gcp-pubsub-dev` in your project and set it as the active stack.



{{< /tab >}} 
{{< tab "Azure (Service Bus)" >}}

Deploy all of the required Schema Registry components for consuming messages from a Service Bus topic.

Log in to the Azure CLI and Pulumi will automatically use your credentials:
```bash
$ az login
```

### Configure your stack
You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers.Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a a pre-configured stack template for your stack. 

```bash
$ pulumi stack init schemaregistry-azure-sb-dev
```
This will create a new stack named `schemaregistry-azure-sb-dev` in your project and set it as the active stack.


{{< /tab >}}

{{< tab "Kafka on Azure" >}}
Deploy all of the required Schema Registry components for consuming messages from a Kafka topic.

Log in to the Azure CLI and Pulumi will automatically use your credentials:
```bash
$ az login
```

### Configure your stack
You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers.Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a a pre-configured stack template for your stack. 

```bash
$ pulumi stack init schemaregistry-azure-kafka-dev
```
This will create a new stack named `schemaregistry-azure-kafka-dev` in your project and set it as the active stack.
{{< /tab >}}

{{< tab "Kafka on GCP" >}}

Deploy all of the required Schema Registry components for consuming messages from a Kafka topic.

Install the Google Cloud SDK and then authorize access with a user account. Next, Pulumi requires default application credentials to interact with your Google Cloud resources, so run auth application-default login command to obtain those credentials:

```bash
$ gcloud auth application-default login
```

### Configure your stack

You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers.Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a a pre-configured stack template for your stack. 

```bash
$ pulumi stack init schemaregistry-gcp-kafka-dev
```
This will create a new stack named `schemaregistry-gcp-kafka-dev` in your project and set it as the active stack.

{{< /tab >}}

{{< /tabs >}}

### Deployment

Preview and deploy infrastructure changes:
```bash
$ pulumi up
```
Destroy your infrastructure changes:
```bash
$ pulumi destroy
```

Following the deployment, the Schema Registry components will begin automatically pulling data from the configured topic and delivering it to the target storage destination.
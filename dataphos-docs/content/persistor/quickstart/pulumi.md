---
title: "Pulumi"
draft: false
weight: 3
---

## Setting Up Your Environment

### Prerequisites

Persistor components run in a Kubernetes environment. This quickstart guide will assume that you have
[Python 3](https://www.python.org/downloads/) and [Pulumi](https://www.pulumi.com/docs/install/) tools installed. Pulumi repository can be accessed on the [Pulumi repository](https://github.com/dataphos/dataphos-infra).

This quickstart guide will assume creating new resources instead of importing existing ones into the active stack. If you wish to import your resources check [Deployment Customization](/persistor/configuration/pulumi).

Persistor has multiple message broker options and storage options. This quickstart guide will assume that the publishing message broker will be either GCP Pub/Sub, Azure ServiceBus, or Kafka, and for storage options Google Cloud Storage(GCS) or Azure Blob Storage.


### Persistor namespace

The namespace where the components will be deployed is defined in the config file, you don't have to create it by yourself. We will use the namespace `dataphos` in this guide. 

```bash
  namespace: dataphos
```

### Download the Persistor Helm chart

The Dataphos Helm charts are located in the [Dataphos Helm Repository](https://github.com/dataphos/dataphos-helm).

To properly reference the Persistor chart, clone the Helm repository and copy the entire `dataphos-persistor` directory into the `helm_charts` directory of this repository.

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

## Persistor deployment

Persistor consists of 4 components: **Persistor Core**, **Indexer**, **Indexer API**, and the **Resubmitter**. 

All four are highly configurable, allowing for a multitude of combinations of brokers and blob storage destinations. In this quickstart, we will outline four of the commonly-used ones. For a complete list and detailed configuration options, we suggest viewing the [Configuration](/persistor/configuration/pulumi) page.

### Cloud provider and stack configuration

{{< tabs "persistorplatform" >}}
{{< tab "GCP (Pub/Sub to GCS)" >}} 

### Google PubSub to Google Cloud Storage

Deploy all of the required Persistor components for consuming messages from a Google PubSub topic and storing them in a Google Cloud Storage account.

Install the Google Cloud SDK and then authorize access with a user account. Next, Pulumi requires default application credentials to interact with your Google Cloud resources, so run auth application-default login command to obtain those credentials:

```bash
$ gcloud auth application-default login
```

### Configure your stack

You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers. Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a pre-configured stack template for your stack. 

```bash
$ pulumi stack init persistor-gcp-pubsub-dev
```
This will create a new stack named `persistor-gcp-pubsub-dev` in your project and set it as the active stack.

{{< /tab >}}

{{< tab "Azure (Service Bus to Azure Blob Storage)" >}} 

### Azure Service Bus to Azure Blob Storage

Deploy all of the required Persistor components for consuming messages from a Service Bus topic and storing them into an Azure Blob Storage account.

Log in to the Azure CLI and Pulumi will automatically use your credentials:
```bash
$ az login
```

### Configure your stack
You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers.Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a pre-configured stack template for your stack. 

```bash
$ pulumi stack init persistor-azure-sb-dev
```
This will create a new stack named `persistor-azure-sb-dev` in your project and set it as the active stack.


{{< /tab >}}
{{< tab "Kafka (to GCS)" >}} 

### Kafka to Google Cloud Storage

Deploy all of the required Persistor components for consuming messages from a Google PubSub topic and storing them in a Google Cloud Storage account.

Install the Google Cloud SDK and then authorize access with a user account. Next, Pulumi requires default application credentials to interact with your Google Cloud resources, so run auth application-default login command to obtain those credentials:

```bash
$ gcloud auth application-default login
```

### Configure your stack
You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers.Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a pre-configured stack template for your stack. 

```bash
$ pulumi stack init persistor-gcp-kafka-dev
```
This will create a new stack named `persistor-gcp-kafka-dev` in your project and set it as the active stack.

{{< /tab >}}
{{< tab "Kafka (to Azure Blob Storage)" >}} 

### Kafka to Azure Blob Storage

Deploy all of the required Persistor components for consuming messages from a Service Bus topic and storing them into an Azure Blob Storage account.

Log in to the Azure CLI and Pulumi will automatically use your credentials:
```bash
$ az login
```

### Configure your stack
You can use a stack configuration template file to quickly deploy and modify common architectures. This repository includes a set of pre-configured templates for different combinations of Dataphos components and cloud providers.Configuration specifics can be found in the Configuration section of this manual.

To start using a stack template, copy the desired file from the config_templates directory into the project root directory. Next, create a new stack to contain your infrastructure configuration. Make sure to use the name of a pre-configured stack template for your stack. 

```bash
$ pulumi stack init persistor-azure-kafka-dev
```
This will create a new stack named `persistor-azure-kafka-dev` in your project and set it as the active stack.


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

Following the deployment, the Persistor component will begin automatically pulling data from the configured topic and delivering it to the target storage destination.

By following the quickstart, the destination will be:

```
{BUCKET/CONTAINER_ID}{TOPIC_ID}/{SUBSCRIPTION_ID or CONSUMER_GROUP_ID}/{YEAR}/{MONTH}/{DAY}/{HOUR}/.*avro
```

The messages will be stored in batches, in the `.avro` format.

## Resubmitter API

The Resubmitter allows the user to resubmit the stored messages to a destination resubmission topic of their choice. While the Resubmitter allows resubmission based on a number of parameters, in this example, we will resubmit messages based on the **time range** they were ingested onto the platform.


### Replaying messages based on the ingestion interval

To resubmit messages using this endpoint, send a **POST** request to the resubmitter service deployed on your Kubernetes cluster:

```bash
http://<rsb_host>:8081/range/indexer_collection?topic=<destination_topic_id>
```

With the `<destination_topic_id>` representing the name of the **destination** topic you wish to replay the messages to. Note that, as a best-practice, this should be different from the original topic messages were pulled from, to ensure message resending does not affect all downstream consumers of the original topic unnecessarily.
  
The actual request body contains the information from which topic data were initally received, and what time range
the messages were received.

In this case, JSON attribute *broker_id* was used.  

```json
{
  "broker_id": "origin_broker_id",
  "lb": "0001-01-01T00:00:00Z",  // Start Date
  "ub": "2023-09-27T14:15:05Z"  // End Date
}
```

In this case, `origin_broker_id` is the ID of message broker from where messages were initially pulled by the Persistor component.

The final request is thus:

```bash
curl -XPOST -H "Content-type: application/json" -d '{
    "broker_id": "origin_broker_id",
    "lb": "0001-01-01T00:00:00Z",
    "ub": "2021-09-27T14:15:05Z"
}' 'http://<rsb-host>:8081/range/<mongo-collection>?topic=<destination_topic_id>'
```
  

By following this example, if you resubmit all the messages with the given `origin_broker_id` to the specified `destination_topic_id`, you should get a response that looks as follows:

```json
{
    "status": 200,
    "msg": "resubmission successful",
    "summary": {
        "indexed_count": 20,
        "fetched_count": 20,
        "deserialized_count": 20,
        "published_count": 20
    },
    "errors": {}
}
```

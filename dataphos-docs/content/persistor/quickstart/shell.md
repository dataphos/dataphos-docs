---
title: "Shell"
draft: false
weight: 1
---

## Setting Up Your Environment

### Prerequisites

Persistor components run in a Kubernetes environment. This quickstart guide will assume that you have
the ```kubectl``` tool installed and a running Kubernetes cluster on one of the major cloud providers (GCP, Azure) and a
connection with the cluster. The Kubernetes cluster node/nodes should have at least 8 GB of available RAM.

Persistor has multiple message broker options and storage options. This quickstart guide will assume that the publishing message
broker will be either GCP Pub/Sub, Azure ServiceBus or Kafka, and for storage options Google Cloud Storage(GCS) or Azure Blob Storage.

{{< tabs "platformconfig" >}}
{{< tab "GCP (Pub/Sub to GCS)" >}} 

## Google PubSub to Google Cloud Storage
- Service account JSON key with the appropriate roles: ([Service Account Creation](https://cloud.google.com/iam/docs/service-accounts-create#iam-service-accounts-create-console), [JSON Key Retrieval](https://cloud.google.com/iam/docs/keys-create-delete))
  - Pub/Sub Editor
  - Storage Object Admin
- Topic the messages should be persisted from 
- The Subscription the Persistor will use to pull the messages from
- Indexer topic and subscription
- Resubmission topic
- GCS bucket
- Optional dead-letter topic (used as a last resort in case of unsolvable issues), with a subscription to retain messages
{{< /tab >}}
{{< tab "Azure (Service Bus to Azure Blob Storage)" >}} 
## Azure Service Bus to Azure Blob Storage 
- Service principal with roles:
  - Azure Service Bus Data Sender
  - Azure Service Bus Data Receiver
  - Storage Blob Data Contributor
  - Don't forget to *save* the `CLIENT_ID`, `CLIENT_SECRET` and `TENANT_ID` values when creating the service principal.
- Service Bus Namespace ([Service Bus Namespace Creation](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quickstart-portal#create-a-namespace-in-the-azure-portal))
- Topic the messages should be persisted from 
- The Subscription the Persistor will use to pull the messages from
- Indexer topic and subscription
- Resubmission topic
- Azure Storage account
- Azure blob storage container
- Optional dead-letter topic (used as a last resort in case of unsolvable issues), with a subscription to retain messages
{{< /tab >}}
{{< tab "Kafka (to GCS)" >}} 
## Kafka to Google Cloud Storage
- An existing Kafka broker. You can create one yourself in a Kubernetes environment via [Strimzi](https://strimzi.io/docs/operators/0.30.0/quickstart.html), should you choose to do so.
- Service account JSON key with the appropriate roles: ([Service Account Creation](https://cloud.google.com/iam/docs/service-accounts-create#iam-service-accounts-create-console), [JSON Key Retrieval](https://cloud.google.com/iam/docs/keys-create-delete))
  - Stackdriver Resource Metadata Writer
  - Logs Writer
  - Monitoring Metric Writer
  - Monitoring Viewer
  - Storage Object Admin
- Topic the messages should be persisted from 
- Indexer topic
- Resubmission topic
- GCS bucket 
- Dead-letter topic (used as a last resort in case of unsolvable issues)
{{< /tab >}}
{{< tab "Kafka (to Azure Blob Storage)" >}} 
## Kafka to Azure Blob Storage
- An existing Kafka broker. You can create one yourself in a Kubernetes environment via [Strimzi](https://strimzi.io/docs/operators/0.30.0/quickstart.html), should you choose to do so.
- Service principal with roles:
  - Storage Blob Data Contributor
  - Don't forget to *save* the `CLIENT_ID`, `CLIENT_SECRET` and `TENANT_ID` values when creating the service principal.
- Topic the messages should be persisted from 
- Indexer topic
- Resubmission topic
- Azure Storage account
- Azure blob storage container
- Dead-letter topic (used as a last resort in case of unsolvable issues)
{{< /tab >}}
{{< /tabs >}}

### Create the Persistor namespace

Before deploying the Persistor, the namespace where the components will be deployed should be created if it
doesn't exist.

Create the namespace where Persistor will be deployed. We will use the namespace `dataphos` in this guide.

```bash
kubectl create namespace dataphos
```

## Deployment

Persistor consists of 4 components: **Persistor Core**, **Indexer**, **Indexer API**, the **Resubmitter**. 

All four are highly configurable, allowing for a multitude of combinations of brokers and blob storage destinations. In this quickstart, we will outline four of the most commonly-used ones. For a complete list and detailed configuration options, we suggest viewing the [Configuration](/persistor/configuration) page.

### Deploy the Persistor

{{< tabs "persistorplatform" >}}
{{< tab "GCP (Pub/Sub to GCS)" >}} 

## Google PubSub to Google Cloud Storage

Deploy all of the required Persistor components for consuming messages from a Google PubSub topic and storing them into a Google Cloud Storage account.

### Arguments

The required arguments are:

- The GCP Project ID
- The name of the topic data will be persisted from
- The Persistor Subscription
- The Bucket data will be persisted to
- The dead letter topic to be used in case of unresolvable errors
- The name of the topic indexation metadata will be sent to
- The Indexer Subscription
- The Path to your locally-stored GCP JSON Service Account Credentials

The script can be found [here](/referenced-scripts/deployment-scripts/persistor/#persistor-gcp). From the content root, to run the script, run the following command:
```bash
# "myProjectID" is the GCP project ID.
# "persistor-topic" is the Topic messages will be pulled form.
# "persistor-sub" is the subscription the Persistor will use to pull the messages from.
# "persistor-bucket" is the name of the GCS bucket the data will be stored to.
# "persistor-dltopic" is the dead letter topic to be used in case of unresolvable errors
# "indexer-topic" is the topic the Indexer metadata will be sent to.
# "indexer-sub" is the subscription the Indexer component will read the metadata from.
# "C:/Users/User/Dekstop/key.json" is the path to the GCP Service Account key file.

./persistor_gcp.sh "myProjectID" "persistor-topic" "persistor-sub" "persistor-bucket" "persistor-dltopic" "indexer-topic" "indexer-sub" "C:/Users/User/Dekstop/key.json" 
```

{{< /tab >}}
{{< tab "Azure (Service Bus to Azure Blob Storage)" >}} 

## Azure Service Bus to Azure Blob Storage

Deploy all of the required Persistor components for consuming messages from a Service Bus topic and storing them into an Azure Blob Storage account.

### Arguments

The required arguments are:

- The `CLIENT_ID` of the Service Principal
- The `CLIENT_SECRET` of the Service Principal
- The `TENANT_ID` of the Service Principal
- The connection string of the namespace the Persistor's target topic is located in
- The name of the topic data will be persisted from
- The Persistor Subscription
- The Azure Storage Account messages will be persisted to
- The main container the messages will be persisted to
- The dead letter topic to be used in case of unresolvable errors
- The connection string of the namespace the Indexer topic is located in
- The name of the topic indexation metadata will be sent to
- The Indexer Subscription

The script can be found [here](/referenced-scripts/deployment-scripts/persistor/#persistor-azure). From the content root, to run the script, run the following command:



```bash
# "19b725a4-1a39-5fa6-bdd0-7fe992bcf33c" is an Azure CLIENT_ID.
# "38c345b5-1b40-7fb6-acc0-5ab776daf44e" is an Azure CLIENT_SECRET.
# "49d537a6-8a49-5ac7-ffe1-6fe225abe33f" is an Azure TENANT_ID.
# "namespace-conn-per" is the connection string of the Service Bus namespace to persist from. The actual value should be something of the form "Endpoint=sb://per-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=..."
# "persistor-topic" is the name of the Service Bus topic to persist from.
# "persistor-sub" is the subscription the Persistor will use to pull the messages from.
# "myaccountstorage" is the name of the Azure Storage Account data will be saved to.
# "persistor-container" is the name of the container data will be saved to.
# "persistor-dltopic" is the dead letter topic to be used in case of unresolvable errors
# "namespace-conn-idx" is the connection string of the Service Bus namespace Indexer metadata will be sent to. The actual value should be something of the form "Endpoint=sb://idx-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=..."
# "indexer-topic" is the topic the Indexer metadata will be sent to.
# "indexer-sub" is the subscription the Indexer component will read the metadata from.

./persistor_azure.sh "19b725a4-1a39-5fa6-bdd0-7fe992bcf33c" "38c345b5-1b40-7fb6-acc0-5ab776daf44e" "49d537a6-8a49-5ac7-ffe1-6fe225abe33f" "namespace-conn-per" "persistor-topic" "persistor-sub" "myaccountstorage" "persistor-container" "persistor-dltopic" "namespace-conn-idx" "indexer-topic" "indexer-sub"
```

{{< /tab >}}
{{< tab "Kafka (to GCS)" >}} 

## Kafka to Google Cloud Storage

Deploy all of the required Persistor components for consuming messages from a Kafka topic and storing them into a Google Cloud Storage bucket.

### Arguments

The required arguments are:

- The GCP Project ID of the GCS bucket the data will be persisted to
- The address of the Kafka broker the topic data will be persisted from is located (the host if the broker is publicly-exposed, alternatively the Kubernetes DNS name)
- The name of the topic data will be persisted from
- The name of the consumer group the Persistor will use
- The Bucket data will be persisted to
- The dead letter topic to be used in case of unresolvable errors
- The address of the Kafka broker the indexing metadata topic is located in
- The name of the topic indexation metadata will be sent to
- The name of the consumer group the Indexer will use
- The Path to your locally-stored GCP JSON Service Account Credentials

The script can be found [here](/referenced-scripts/deployment-scripts/persistor/#persistor-kafka-to-gcs). From the content root, to run the script, run the following command:
```bash
# "myProjectID" is the GCP project ID the storage account is located in.
# "[10.20.0.10]" is (one of) the IPs to the Kafka Bootstrap server of the cluster we are persisting from.
# "persistor-topic" is the Topic messages will be pulled form.
# "Persistor" is example of consumer group the Persistor will use.
# "persistor-bucket" is the name of the GCS bucket the data will be stored to.
# "persistor-dltopic" is the dead letter topic to be used in case of unresolvable errors.
# "["10.20.0.10"] is (one of) the IPs to the Kafka Bootstrap server of the cluster the Indexer is located in.
# "indexer-topic" is the topic the Indexer metadata will be sent to.
# "Indexer" is example of consumer group for indexer.
# "C:/Users/User/Dekstop/key.json" is the path to the GCP Service Account key file.

./persistor_kafka_gcs.sh "myProjectID" "[10.20.0.10]" "persistor-topic" "Persistor" "persistor-bucket" "persistor-dltopic" "[10.20.0.10]" "indexer_topic" "Indexer" "C:/Users/User/Dekstop/key.json" 
```

{{< /tab >}}
{{< tab "Kafka (to Azure Blob Storage)" >}} 

## Kafka to Azure Blob Storage

Deploy all of the required Persistor components for consuming messages from a Kafka topic and storing them into an Azure Blob Storage account.

### Arguments

The required arguments are:

- The `CLIENT_ID` of the Service Principal
- The `CLIENT_SECRET` of the Service Principal
- The `TENANT_ID` of the Service Principal
- The address of the Kafka broker the topic data will be persisted from is located (the host if the broker is publicly-exposed, alternatively the Kubernetes DNS name)
- The name of the topic data will be persisted from
- The name of the consumer group the Persistor will use
- The Azure Storage Account messages will be persisted to
- The main container the messages will be persisted to
- The dead letter topic to be used in case of unresolvable errors
- The address of the Kafka broker the indexing metadata topic is located in
- The name of the topic indexation metadata will be sent to
- The name of the consumer group the Indexer will use

The script can be found [here](/referenced-scripts/deployment-scripts/persistor/#persistor-kafka-to-azure-blog-storage). From the content root, to run the script, run the following command:
```bash
# "19b725a4-1a39-5fa6-bdd0-7fe992bcf33c" is an Azure CLIENT_ID.
# "38c345b5-1b40-7fb6-acc0-5ab776daf44e" is an Azure CLIENT_SECRET.
# "49d537a6-8a49-5ac7-ffe1-6fe225abe33f" is an Azure TENANT_ID.
# "[10.20.0.10]" is (one of) the IPs to the Kafka Bootstrap server of the cluster we are persisting from.
# "persistor-topic" is the Topic messages will be pulled form.
# "Persistor" is example of consumer group the Persistor will use.
# "myaccountstorage" is the name of the Azure Storage Account data will be saved to.
# "persistor-container" is the name of the container data will be saved to.
# "persistor-dltopic" is the dead letter topic to be used in case of unresolvable errors
# "["10.20.0.10"] is (one of) the IPs to the Kafka Bootstrap server of the cluster the Indexer is located in.
# "indexer-topic" is the topic the Indexer metadata will be sent to.
# "Indexer" is example of consumer group for indexer.

./persistor_kafka_az_blob.sh "19b725a4-1a39-5fa6-bdd0-7fe992bcf33c" "38c345b5-1b40-7fb6-acc0-5ab776daf44e" "49d537a6-8a49-5ac7-ffe1-6fe225abe33f" "[10.20.0.10]" "persistor-topic" "Persistor" "myaccountstorage" "persistor-container" "persistor-dltopic" "[10.20.0.10]" "indexer-topic" "Indexer"
```

{{< /tab >}}
{{< /tabs >}}

Following the deployment, the Persistor component will being automatically pulling data from the configured topic and delivering it to the target storage destination.

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

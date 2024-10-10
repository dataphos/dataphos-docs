---
title: "Helm"
draft: false
weight: 2
---

## Setting Up Your Environment

### Prerequisites

This quickstart guide will assume that you have [Helm](https://helm.sh/) installed.
If you happen to be using VS Code make sure to have the Kubernetes and Helm extensions installed to make life a little easier for you. Helm repository can be accessed on the [Helm repository](https://github.com/dataphos/dataphos-helm).

Persistor has multiple message broker options and storage options. This quickstart guide will assume that the publishing message broker will be either GCP Pub/Sub, Azure ServiceBus or Kafka, and for storage options Google Cloud Storage(GCS) or Azure Blob Storage. These resources must be running before the deployment:

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

### Chart Usage  

Each chart has its own configuration settings outlined in its respective subfolder. A `values.yaml` file should be prepared and pass to Helm while performing the installation. Chart can be accessed on the [Helm repository](https://github.com/dataphos/dataphos-helm/tree/main/dataphos-persistor).

To deploy the `dataphos-persistor` chart, run:

```bash
helm install persistor ./dataphos-persistor
```

This causes the `values.yaml` file to be read from the root directory of the `dataphos-persistor` folder. The `--values flag` may be passed in the call to override this behavior.

You can also add a `--dry-run` flag that will simply generate the Kubernetes manifests and check if they are valid (note that this requires `kubectl` to be configured against an actual cluster). For general linting of the Helm templates, run `helm lint`.

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

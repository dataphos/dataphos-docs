---
title: "Helm"
draft: false
weight: 2
---

## Setting up your environment

### Prerequisites

This quickstart guide will assume that you have [Helm](https://helm.sh/) installed and a running Kubernetes cluster on one of the major cloud providers (GCP, Azure). If you happen to be using VS Code make sure to have the Kubernetes and Helm extensions installed to make life a little easier for you. Helm repository can be accessed on the [Helm repository](https://github.com/dataphos/dataphos-helm).

Resources that are used must be running before the deployment.
Schema Registry has multiple message broker options. This quickstart guide will assume that the publishing message
broker and the consuming message broker will be either GCP Pub/Sub, Azure ServiceBus or Kafka, and that you have
created:

{{< tabs "platformconfig" >}}
{{< tab "GCP" >}} 
-  Service account JSON key with the appropriate roles (Pub/Sub Publisher, Pub/Sub Subscriber) ([Service Account Creation](https://cloud.google.com/iam/docs/service-accounts-create#iam-service-accounts-create-console), [JSON Key Retrieval](https://cloud.google.com/iam/docs/keys-create-delete))
- An input topic and subscription (The input topic refers to the topic that contains the data in its original
  format)
- Valid topic and subscription (The valid topic refers to the topic where the data is stored after being validated
  and serialized using a specific schema)
- Dead-letter topic and subscription (The valid topic refers to the topic where messages that could not be processed
  by a consumer are stored for troubleshooting and analysis purposes)
- (optional) Prometheus server for gathering the metrics and monitoring the logs
    - Can be deployed quickly using [this deployment script](https://github.com/dataphos/dataphos-docs/blob/main/scripts/prometheus.sh)

{{< /tab >}}
{{< tab "Azure ServiceBus" >}} 
- ServiceBus connection string
- An input topic and subscription (The input topic refers to the topic that contains the data in its original
  format)
- Valid topic and subscription (The valid topic refers to the topic where the data is stored after being validated
  and serialized using a specific schema)
- Dead-letter topic and subscription (The valid topic refers to the topic where messages that could not be processed
  by a consumer are stored for troubleshooting and analysis purposes)
- (optional) Prometheus server for gathering the metrics and monitoring the logs
    - Can be deployed quickly using [this deployment script](https://github.com/dataphos/dataphos-docs/blob/main/scripts/prometheus.sh)

{{< /tab >}}
{{< tab "Kafka" >}} 
- Kafka broker. You may deploy one onto your Kubernetes environment via [Strimzi](https://strimzi.io/docs/operators/0.30.0/quickstart.html)
- An input topic (The input topic refers to the topic that contains the data in its original
  format)
- Valid topic (The valid topic refers to the topic where the data is stored after being validated
  and serialized using a specific schema)
- Dead-letter topic (The valid topic refers to the topic where messages that could not be processed
  by a consumer are stored for troubleshooting and analysis purposes)
- (optional) Prometheus server for gathering the metrics and monitoring the logs
    - Can be deployed quickly using [this deployment script](https://github.com/dataphos/dataphos-docs/blob/main/scripts/prometheus.sh)

{{< /tab >}}
{{< /tabs >}}

### Create the Schema Registry namespace

Before deploying the Schema Registry, the namespace where the components will be deployed should be created if it
doesn't exist.

Open a command line tool of your choice and connect to your cluster. Create the namespace where Schema Registry will be
deployed. We will use namespace `dataphos` in this quickstart guide.

```bash
kubectl create namespace dataphos
```

## Deployment
Schema registry is separated into two components: the registry component and the validators component.

The registry component is used as a central schema management system that provides options of schema registration and versioning as well as schema validity and compatibility checking. Therefore, it is usually deployed only once.

The validator component acts as a message validation system, meaning that it consists of validators that validate the message for the given message schema. The validator supports JSON, AVRO, ProtoBuf, XML and CSV message formats. The idea is to have multiple validator components for every topic you wish to validate the schemas for and therefore the validator component might be deployed multiple times.
## Deploy the Schema Registry - Registry Component

###  Arguments

The required arguments are:

- The Kubernetes namespace you will be deploying the registry to
- Schema History Postgres database password

### Chart Usage

Each chart has its own configuration settings outlined in its respective subfolder. A `values.yaml` file should be prepared and pass to Helm while performing the installation. Chart can be accessed on the [Helm repository](https://github.com/dataphos/dataphos-helm/tree/main/dataphos-schema-registry).

To deploy the `dataphos-schema-registry` chart, run:

```
helm install schema-registry ./dataphos-schema-registry
```

This would cause the `values.yaml` file to be read from the root directory of the `dataphos-schema-registry` folder. The `--values` flag may be passed in the call to override this behavior.

You can also add a `--dry-run` flag that will simply generate the Kubernetes manifests and check if they are valid (note that this requires `kubectl` to be configured against an actual cluster). For general linting of the Helm templates, run `helm lint`. 

## Deploy the Schema Registry - Validator Component

You can deploy the **Validator** component of the Schema Registry using the provided deployment script.

{{< tabs "Schema Registry - validator component deployment" >}} {{< tab "GCP Pub/Sub" >}}

### Arguments

The required arguments are:

- The Kubernetes namespaces to deploy the validator component to
- Producer Pub/Sub valid topic ID
- Producer Pub/Sub dead-letter topic ID
- Expected message format validated by this validator (json, avro, protobuf, csv, xml)
- Consumer GCP Project ID
- Consumer Pub/Sub Subscription ID (created beforehand)
- Producer GCP Project ID

{{< /tab >}} {{< tab "Azure (Service Bus)" >}}

### Arguments

Required arguments are:

- The Kubernetes namespaces to deploy the validator component to
- Producer ServiceBus valid topic ID
- Producer ServiceBus dead-letter topic ID
- Expected message format validated by this validator (json, avro, protobuf, csv, xml)
- Consumer ServiceBus Connection String
- Consumer ServiceBus Topic
- Consumer ServiceBus Subscription
- Producer ServiceBus Connection String

{{< /tab >}}

{{< tab "Kafka" >}}

### Arguments

Required arguments are:

- The Kubernetes namespaces to deploy the validator component to
- Producer Kafka valid topic ID
- Producer Kafka dead-letter topic ID
- Expected message format validated by this validator (json, avro, protobuf, csv, xml)
- Consumer Kafka broker address
- Consumer Kafka Topic
- Consumer Kafka Group ID
- Producer Kafka broker address

{{< /tab >}}

{{< tab "Kafka to Pub/Sub (Consumer Kafka, producer GCP Pub/Sub)" >}}

### Arguments

Required arguments are:

- The Kubernetes namespaces to deploy the validator component to
- Producer Kafka valid topic ID
- Producer Kafka dead-letter topic ID
- Expected message format validated by this validator (json, avro, protobuf, csv, xml)
- Consumer Kafka Connection String
- Consumer Kafka Topic
- Consumer Kafka Subscription
- Producer GCP Project ID

{{< /tab >}}

{{< /tabs >}}

### Deployment

Each chart has its own configuration settings outlined in its respective subfolder. A `values.yaml` file should be prepared and pass to Helm while performing the installation. Chart can be accessed on the [Helm repository](https://github.com/dataphos/dataphos-helm/tree/main/dataphos-schema-registry-validator).

To deploy the `dataphos-schema-validator` chart, run:

```
helm install schema-validator ./dataphos-schema-validator
```

This would cause the `values.yaml` file to be read from the root directory of the `dataphos-schema-validator` folder. The `--values` flag may be passed in the call to override this behavior.

You can also add a `--dry-run` flag that will simply generate the Kubernetes manifests and check if they are valid (note that this requires `kubectl` to be configured against an actual cluster). For general linting of the Helm templates, run `helm lint`. 
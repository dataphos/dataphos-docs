---
title: "Shell"
draft: false
weight: 1
---

## Setting up your environment

### Prerequisites

Schema Registry components run in a Kubernetes environment. This quickstart guide will assume that you have
the ```kubectl``` tool installed and a running Kubernetes cluster on one of the major cloud providers (GCP, Azure) and a
connection with the cluster. The Kubernetes cluster node/nodes should have at least 8 GB of available RAM.

Schema Registry has multiple message broker options. This quickstart guide will assume that the publishing message
broker and the consuming message broker will be either GCP Pub/Sub, Azure ServiceBus or Kafka, and that you have
created:

- (in case of GCP Pub/Sub) service account JSON key with the appropriate roles (Pub/Sub Publisher, Pub/Sub Subscriber) ([Service Account Creation](https://cloud.google.com/iam/docs/service-accounts-create#iam-service-accounts-create-console), [JSON Key Retrieval](https://cloud.google.com/iam/docs/keys-create-delete))
- (in case of Azure ServiceBus) ServiceBus connection string
- (in case of Kafka) Kafka broker. You may deploy one onto your Kubernetes environment via [Strimzi](https://strimzi.io/docs/operators/0.30.0/quickstart.html).
- An input topic and subscription (The input topic refers to the topic that contains the data in its original
  format)
- Valid topic and subscription (The valid topic refers to the topic where the data is stored after being validated
  and serialized using a specific schema)
- Dead-letter topic and subscription (The valid topic refers to the topic where messages that could not be processed
  by a consumer are stored for troubleshooting and analysis purposes)
- (optional) Prometheus server for gathering the metrics and monitoring the logs
    - Can be deployed quickly using [this deployment script](/referenced-scripts/deployment-scripts/prometheus/#bash)

Note that in case of Kafka, no subscription resource is required.

> **NOTE:**  All the deployment scripts can be found [here](/referenced-scripts/).

### Create the Schema Registry namespace

Before deploying the Schema Registry, the namespace where the components will be deployed should be created if it
doesn't exist.

Open a command line tool of your choice and connect to your cluster. Create the namespace where Schema Registry will be
deployed. We will use namespace `dataphos` in this quickstart guide.

```bash
kubectl create namespace dataphos
```

## Deployment

Schema registry is separated into two components: the **registry** component and the **validator** component.

The registry component is used as a central schema management system that provides options for schema registration and
versioning as well as schema validity and compatibility checking. Therefore, it is usually deployed only once.

The validator component acts as a message validation system, meaning that it consists of validators that validate the
message for the given message schema. The validator supports JSON, AVRO, ProtoBuf, XML and CSV message formats. The idea is
to have multiple validator components for every topic you wish to validate the schemas for and therefore the validator
component might be deployed multiple times.

## Deploy the Schema Registry - Registry Component

You can deploy the **Registry** server component using the provided deployment script.

### Arguments

The required arguments are:

- The Kubernetes namespace you will be deploying the registry to
- Schema History Postgres database password

### Deployment

The script can be found [here](/referenced-scripts/deployment-scripts/schemaregistry/#schema-registry-api). To run the script, run the
following command:

```bash
# "dataphos" is an example of the namespace name
# "p4sSw0rD" is example of the Schema History Postgres password
./sr_registry.sh dataphos p4sSw0rD
```

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

### Deployment

The script can be found [here](/referenced-scripts/deployment-scripts/schemaregistry/#schema-registry-validator-pubsub). To run the script, run the
following command:

```bash
# "dataphos" is an example of the namespace name
# "valid-topic" is example of the valid topic name
# "dead-letter-topic" is example of the dead-letter topic name
# "json" is example of the message format name (needs to be either "json", "avro", "csv", "xml", "protobuf")
# "dataphos-project" is example of the consumer GCP project ID
# "input-topic-sub" is example of the input topic subcription name
# "dataphos-project" is example of the producer GCP project ID

./validator-pubsub.sh "dataphos" "valid-topic" "dead-letter-topic" "json" "dataphos-project" "input-topic-sub" "dataphos-project" 
```

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

### Deployment

The script can be found [here](/referenced-scripts/deployment-scripts/schemaregistry/#schema-registry-validator-servicebus) To run the script, run the
following command:

```bash
# "dataphos" is an example of the namespace name
# "valid-topic" is example of the valid topic name
# "dead-letter-topic" is example of the dead-letter topic name
# "json" is example of the message format name (needs to be either "json", "avro", "csv", "xml", "protobuf")
# "Endpoint=sb://foo.servicebus.windows.net/;SharedAccessKeyName=someKeyName;SharedAccessKey=someKeyValue" is example of the consumer ServiceBus connection string (https://azurelessons.com/azure-service-bus-connection-string/)
# "input-topic" is example of the input topic name
# "input-topic-sub" is example of the input topic subcription name
# "Endpoint=sb://foo.servicebus.windows.net/;SharedAccessKeyName=someKeyName;SharedAccessKey=someKeyValue" is example of the producer ServiceBus connection string (https://azurelessons.com/azure-service-bus-connection-string/)

./validator-servicebus.sh "dataphos" "valid-topic" "dead-letter-topic" "json" "Endpoint=sb://foo.servicebus.windows.net/;SharedAccessKeyName=someKeyName;SharedAccessKey=someKeyValue" "input-topic" "input-topic-sub" "Endpoint=sb://foo.servicebus.windows.net/;SharedAccessKeyName=someKeyName;SharedAccessKey=someKeyValue" 
```

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

### Deployment

The script can be found [here](/referenced-scripts/deployment-scripts/schemaregistry/#schema-registry-validator-kafka) To run the script, run the
following command:

```bash
# "dataphos" is an example of the namespace name
# "valid-topic" is example of the valid topic name
# "dead-letter-topic" is example of the dead-letter topic name
# "json" is example of the message format name (needs to be either "json", "avro", "csv", "xml", "protobuf")
# "127.0.0.1:9092" is example of the consumer Kafka broker address
# "input-topic" is example of the input topic name
# "group01" is example of the input topic group ID
# "127.0.0.1:9092" is example of the producer Kafka broker address

./validator-kafka.sh "dataphos" "valid-topic" "dead-letter-topic" "json" "127.0.0.1:9092" "input-topic" "group01" "127.0.0.1:9092" 
```

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

### Deployment

The script can be found [here](/referenced-scripts/deployment-scripts/schemaregistry/#schema-registry-validator-kafka-to-pubsub) To run the script, run the
following command:

```bash
# "dataphos" is an example of the namespace name
# "valid-topic" is example of the valid topic name
# "dead-letter-topic" is example of the dead-letter topic name
# "json" is example of the message format name (needs to be either "json", "avro", "csv", "xml", "protobuf")
# "127.0.0.1:9092" is example of the consumer Kafka broker address
# "input-topic" is example of the input topic name
# "group01" is example of the input topic group ID
# "dataphos-project" is example of the producer GCP project ID

./validator-kafka-to-pubsub.sh "dataphos" "valid-topic" "dead-letter-topic" "json" "<consumer-kafka-broker-address>" "input-topic" "group01" "dataphos-project" 
```

{{< /tab >}}

{{< /tabs >}}

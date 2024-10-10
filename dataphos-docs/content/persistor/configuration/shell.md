---
title: "Shell"
draft: false
weight: 1
---

# Configuration

Persistor is deployed as a set of Kubernetes resources, each of which is highly configurable.

The tables below contain the variables that can be configured as part of the Persistor's configuration.

## Persistor Core

Below are the variables used to configure the main Persistor component. The broker-specific configuration options should be taken into consideration along with the "Common" variables.

{{< tabs "Configuration" >}} 
{{< tab "Common Configuration" >}}

## Common Configuration

Below is the shared configuration used between all Persistor types.

| Variable                   | Example Value       | Possible Values                                     | Description                                                                                                          | Required                                                   |
|----------------------------|---------------------|-----------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------|
| READER_TYPE                | "pubsub"            | ["pubsub", "kafka", "servicebus"]                   | Type of broker used for reader                                                                                       | yes                                                        |
| SENDER_TYPE                | "pubsub"            | ["pubsub", "kafka", "servicebus"]                   | Type of broker used for sender                                                                                       | no (yes if dead letter or indexer are enabled)             |
| STORAGE_TYPE               | "gcs"               | ["azure", "gcs"]                                    | Type of storage used                                                                                                 | yes                                                        |
| STORAGE_DESTINATION        | "my_bucket"         | N/A                                                 | Name of GCS bucket or ABS container                                                                                  | yes                                                        |
| STORAGE_TOPICID            | "my_topic"          | N/A                                                 | Topic's name                                                                                                         | yes                                                        |
| STORAGE_EXTENSION          | "avro"              | N/A                                                 | Extension of the files stored to blob storage.                                                                       | yes                                                        |
| DEADLETTERENABLED          | "true"              | ["true", "false"]                                   | Whether messages will be sent to dead letter upon error                                                              | Default: "true" (must not set to false if reader is kafka) |
| SENDER_DEADLETTERTOPIC     | "persistor_dltopic" | N/A                                                 | Dead letter topic name                                                                                               | no (yes if reader is kafka)                                |

### Enabling the Indexer Plugin

Below are the variables to be used when deploying the Persistor alongside the Indexer plugin. 

| Variable               | Example Value            | Possible Values                                                   |                              Description                              | Required                                              |
|------------------------|--------------------------|-------------------------------------------------------------------|:---------------------------------------------------------------------:|-------------------------------------------------------|
| INDEXERENABLED         | "true"                   | ["true", "false"]                                                 |           Whether to send messages to Indexer topic or not.           | Default: true (set to false if Indexer is not needed) |
| SENDER_TOPICID         | "persistor-indexertopic" | N/A                                                               | ID of the topic used for communication between Persistor and Indexer. | yes if indexer is enabled                             |

{{</ tab>}}
{{< tab "Additional Configuration" >}}

## Additional Configuration

Below are more advanced configuration options available as part of the Persistor's configuration suite.

| Variable                   | Example Value            | Possible Values                                                                             | Description                                                                                                          | Required                        |
|----------------------------|--------------------------|---------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|---------------------------------|
| BATCHSETTINGS_BATCHSIZE    | "5000"                   | N/A                                                                                         | Maximum number of messages in a batch.                                                                               | Default:  5000                 |
| BATCHSETTINGS_BATCHMEMORY  | "1000000"                | N/A                                                                                         | Maximum bytes in batch.                                                                                              | Default:  1000000                   |
| BATCHSETTINGS_BATCHTIMEOUT | "30s"                    | N/A                                                                                         | Time to wait before writing batch if it is not full.                                                                 | Default:  30s               |
| STORAGE_MASK               | "day/hour"               | any subset of (year, month, day, hour), custom values and message attributes separated by / | Path within a blob storage where messages will be saved.                                                             | Default: "year/month/day/hour/"    |
| STORAGE_CUSTOMVALUES       | "org:company,dept:sales" | Comma-separated list of pairs of the form key:value                                         | Values to include in file path. If it contains key1:value1 and STORAGE_MASK has key1, then path will contain value1. | no                              |
| MINIMUM_LOG_LEVEL          | "WARN"                   | ["WARN", "ERROR", "INFO"]                                                                   | The minimal level used in logs.                                                                                      | Default: "INFO"                 |
| STORAGE_PREFIX             | "msg"                    | N/A                                                                                         | Prefix to be given to all files stored to the chosen target blob storage.                                            | Default: "msg"                  |


### Notes on storage path

Batch locations on storage can be made dependent on message attributes. If batching by a specific message attribute key is desired, it needs to be included in the `STORAGE_MASK` variable between curly {} parentheses. Messages with missing attributes will have the appropriate part of the path replaced by the `unknown` keyword.

If STORAGE_MASK is configured as `month/day/{schema_ID}/{publish_reason}`, messages received on October 31 with metadata `{schema_ID:schema_A, publish_reason:audit}` will be stored in blobs under the path `10/31/schema_A/audit`. The remaining attributes other than these two have no effect on the batching.

Messages missing the `publish_reason` metadata key will be batched in `10/31/schema_A/unknown`.

The start of a path can be configured using custom values. If `STORAGE_MASK` starts with `path_prefix/` and the variable `STORAGE_CUSTOMVALUES` is set to `path_prefix:persistor-location`, paths in the chosen blob storage destination will start with `persistor-location/`.

{{</ tab>}}
{{< tab "GCP Pub/Sub" >}}

## GCP Configuration

Below are the variables relevant to users utilizing Google PubSub as the broker type messages are being pulled from and/or using Google Cloud Storage as the destination storage option.

### PubSub used

| Variable                | Example Value    | Possible Values |                 Description                 | Required                                       |
|-------------------------|------------------|-----------------|:-------------------------------------------:|------------------------------------------------|
| READER_PUBSUB_PROJECTID | "my-gcp-project" | N/A             |   ID of the GCP project you're working on   | yes                                            |
| SENDER_PUBSUB_PROJECTID | "my-gcp-project" | N/A             |   ID of the GCP project you're working on   | no (yes if indexer or dead letter are enabled) |
| READER_PUBSUB_SUBID     | "persistor-sub"  | N/A             | Pubsub subscription that messages come from | yes                                            |

{{</ tab>}}
{{< tab "Azure" >}}

## Azure Configuration

Below are the variables relevant to users utilizing Azure Service Bus as the broker type messages are being pulled from and/or using Azure Blob Storage as the destination storage option.

### Common Configuration

| Variable            | Example Value                          | Possible Values | Description                              | Required |
|---------------------|----------------------------------------|-----------------|------------------------------------------|----------|
| AZURE_CLIENT_ID     | "19b725a4-1a39-5fa6-bdd0-7fe992bcf33c" | N/A             | Client ID of your Service Principal      | yes      |
| AZURE_TENANT_ID     | "38c345b5-1b40-7fb6-acc0-5ab776daf44e" | N/A             | Tenant ID of your Service Principal      | yes      |
| AZURE_CLIENT_SECRET | "49d537a6-8a49-5ac7-ffe1-6fe225abe33f" | N/A             | Client secret of your Service Principal  | yes      |

### Azure Service Bus used

| Variable                           | Example Value            | Possible Values |                      Description                       | Required                                      |
|------------------------------------|--------------------------|-----------------|:------------------------------------------------------:|-----------------------------------------------|
| READER_SERVICEBUS_CONNECTIONSTRING | "Endpoint=sb://..."      | N/A             |    Connection string for the service bus namespace     | yes                                           |
| READER_SERVICEBUS_TOPICID          | "persistor-topic"        | N/A             |                 Service bus topic name                 | yes                                           |
| READER_SERVICEBUS_SUBID            | "persistor-subscription" | N/A             |             Service bus subscription name              | yes                                           |
| SENDER_SERVICEBUS_CONNECTIONSTRING | "Endpoint=sb://..."      | N/A             | Connection string for the sender service bus namespace | no (yes is indexer or deadletter are enabled) |

### Azure Blob Storage used
| Variable                 | Example Value            | Possible Values |        Description        | Required                                      |
|--------------------------|--------------------------|-----------------|:-------------------------:|-----------------------------------------------|
| STORAGE_STORAGEACCOUNTID | "persistor-storage"      | N/A             | ID of the storage account | yes                                           |

{{</ tab>}}
{{< tab "Kafka" >}}

## Kafka Configuration

Below are the variables relevant to users utilizing Apache Kafka as the broker type messages are being pulled from. Should be used in conjunction with GCS and Azure Blob Storage as the destination storage of choice.

### Kafka used

| Variable                    | Example Value     | Possible Values |                  Description                  | Required |
|-----------------------------|-------------------|-----------------|:---------------------------------------------:|----------|
| READER_KAFKA_ADDRESS        | "localhost:9092"  | N/A             |          Address of the kafka broker          | yes      |
| READER_KAFKA_GROUPID        | "persistor"       | N/A             |            Consumer group's name.             | yes      |
| READER_KAFKA_TOPICID        | "persistor-topic" | N/A             |            Kafka source topic name            | yes      |
| SENDER_KAFKA_ADDRESS        | "localhost:9092"  | N/A             |    Address of the kafka broker for sender     | yes      |

{{</ tab>}}
{{</ tabs>}}

## Indexer

Below are the variables used to configure the Indexer component -- the component responsible for pulling the Indexer metadata generated by the Persistor from the dedicated broker configuration and storing it in the NoSQL (Mongo) database for resubmission purposes. 

An Indexer "type" is determined based on the message broker used as the communication channel to receive the required metadata.

{{< tabs "Indexer Configuration" >}} 
{{< tab "Common Configuration" >}}

## Common Configuration

Below is the shared configuration between all Indexer types.

| Variable                   | Example Value                                    | Possible Values                   | Description                                                 | Required                                                         |
|----------------------------|--------------------------------------------------|-----------------------------------|-------------------------------------------------------------|------------------------------------------------------------------|
| READER_TYPE                | "pubsub"                                         | ["pubsub", "kafka", "servicebus"] | Type of broker used                                         | yes                                                              |
| SENDER_TYPE                | "pubsub"                                         | ["pubsub", "kafka", "servicebus"] | Type of broker used for sender                              | no (yes if reader is kafka or if indexer is enabled)             |
| DEADLETTERENABLED          | "true"                                           | ["true", "false"]                 | Whether messages will be sent to dead letter upon error     | no (yes, "true" if reader is kafka, otherwise defaults to false) |
| SENDER_DEADLETTERTOPIC     | "persistor-dltopic"                              | N/A                               | Dead letter topic name                                      | no (yes if reader is kafka)                                      |
| MONGO_CONNECTIONSTRING     | "mongodb://mongo-0.mongo-service.dataphos:27017" | N/A                               | MongoDB connection string                                   | yes                                                              |
| MONGO_DATABASE             | "indexer_db"                                     | N/A                               | Mongo database name to store metadata in                    | yes                                                              |
| MONGO_COLLECTION           | "indexer_collection"                             | N/A                               | Mongo collection name (will be created if it doesn’t exist) | yes                                                              |
| MINIMUM_LOG_LEVEL          |  "WARN"                                          | ["WARN", "ERROR", "INFO"]         | The minimal level used in logs.                             | Default: "INFO"                                                  |

{{</ tab >}} 

{{< tab "Advanced Configuration" >}}

## Advanced Configuration

Below are the additional configuration options offered by the Indexer.

| Variable                   | Example Value                        | Possible Values           | Description                                              | Required          |
|----------------------------|--------------------------------------|---------------------------|----------------------------------------------------------|-------------------|
| BATCHSETTINGS_BATCHSIZE    | "5000"                               | N/A                       | Maximum number of messages in a batch.                   | Default:  5000    |
| BATCHSETTINGS_BATCHMEMORY  | "1000000"                            | N/A                       | Maximum bytes in batch.                                  | Default:  1000000 |
| BATCHSETTINGS_BATCHTIMEOUT | "30s"                                | N/A                       | Time to wait before writing batch if it is not full.     | Default:  30s     |

{{</ tab >}} 

{{< tab "GCP" >}}

## GCP Configuration

Below are the configuration options if Google PubSub is used as the communication channel between the components.

| Variable                | Example Value    | Possible Values |                 Description                 | Required                        |
|-------------------------|------------------|-----------------|:-------------------------------------------:|---------------------------------|
| READER_PUBSUB_PROJECTID | "my-gcp-project" | N/A             |   ID of the GCP project you're working on   | yes                             |
| SENDER_PUBSUB_PROJECTID | "my-gcp-project" | N/A             |   ID of the GCP project you're working on   | no (yes dead letter is enabled) |
| READER_PUBSUB_SUBID     | "indexer-sub"    | N/A             | Pubsub subscription that messages come from | yes                             |

{{</ tab >}} 
{{< tab "Azure" >}}

### Azure Service Bus Configuration

Below are the configuration options if Azure Service Bus is used as the communication channel between the components.

| Variable                           | Example Value             | Possible Values |                      Description                       | Required                                      |
|------------------------------------|---------------------------|-----------------|:------------------------------------------------------:|-----------------------------------------------|
| READER_SERVICEBUS_CONNECTIONSTRING | "Endpoint=sb://..."       | N/A             |    Connection string for the service bus namespace     | yes                                           |
| READER_SERVICEBUS_TOPICID          | "persistor-indexer-topic" | N/A             |                 Service bus topic name                 | yes                                           |
| READER_SERVICEBUS_SUBID            | "indexer-subscription"    | N/A             |             Service bus subscription name              | yes                                           |
| SENDER_SERVICEBUS_CONNECTIONSTRING | "Endpoint=sb://..."       | N/A             | Connection string for the sender service bus namespace | no (yes is indexer or deadletter are enabled) |

{{</ tab >}} 
{{< tab "Kafka" >}}


### Kafka Configuration

Below are the configuration options if Apache Kafka is used as the communication channel between the components.

| Variable                    | Example Value    | Possible Values |                  Description                  | Required |
|-----------------------------|------------------|-----------------|:---------------------------------------------:|----------|
| READER_KAFKA_ADDRESS        | "localhost:9092" | N/A             |          Address of the kafka broker          | yes      |
| READER_KAFKA_GROUPID        | "indexer"        | N/A             |            Consumer group's name.             | yes      |
| READER_KAFKA_TOPICID        | "indexer-topic"  | N/A             |            Kafka source topic name            | yes      |
| SENDER_KAFKA_ADDRESS        | "localhost:9092" | N/A             |    Address of the kafka broker for sender     | yes      |

{{</ tab >}} 
{{</ tabs>}}

# Indexer API

The Indexer API is created on top of the initialized Mongo database and used to query the Indexer metadata.

{{< tabs "Indexer API Configuration" >}} 
{{< tab "Simple Configuration" >}}

## Simple Configuration

Below are the minimum configuration options required for the Indexer API to work.

| Variable          | Example Value                           | Possible Values           |                      Description                       | Required         |
|-------------------|-----------------------------------------|---------------------------|:------------------------------------------------------:|------------------|
| CONN              | "mongodb://mongo-0.mongo-service:27017" | N/A                       |               MongoDB connection string.               | yes              |
| DATABASE          | "indexer_db"                            | N/A                       | MongoDB database from which Indexer will read messages | yes              |


{{</ tab >}} 
{{< tab "Advanced Configuration" >}}

## Advanced Configuration

Below are additional configuration options offered by the Indexer API.

| Variable          | Example Value                           | Possible Values           |                      Description                       | Required         |
|-------------------|-----------------------------------------|---------------------------|:------------------------------------------------------:|------------------|
| MINIMUM_LOG_LEVEL | "WARN"                                  | ["WARN", "ERROR", "INFO"] |            The minimal level used in logs.             | Default: "INFO"  |
| SERVER_ADDRESS    | ":8080"                                 | N/A                       |   Port on which Indexer API will listen for traffic    | Default: ":8080" |
| USE_TLS           | "false"                                 | ["true", "false"]         |               Whether to use TLS or not                | Default: "false" |
| SERVER_TIMEOUT    | "2s"                                    | N/A                       |   The amount of time allowed to read request headers   | Default: "2s"    |

{{</ tab >}} 
{{</ tabs>}}

# Resubmitter API

The Resubmitter API is connected to the Indexer API for efficient fetching of data. It is dependent on the type of storage it is meant to query and the destination broker.

{{< tabs "Resubmitter API Configuration" >}} 
{{< tab "Common Configuration" >}}

## Common Configuration

Below are the common configuration options for the Resubmitter API.

| Variable           | Example Value               | Possible Values                   |                                 Description                                 | Required         |
|--------------------|-----------------------------|-----------------------------------|:---------------------------------------------------------------------------:|------------------|
| INDEXER_URL        | "http://34.77.44.130:8080/" | N/A                               | The URL of the Indexer API with which the Resubmitter will communicate with | yes              |
| STORAGE_TYPE       | "gcs"                       | ["gcs", "abs"]                    |                      Type of storage used by Persistor                      | yes              |
| PUBLISHER_TYPE     | "pubsub"                    | ["servicebus", "kafka", "pubsub"] |                             Type of broker used                             | yes              |
| SERVER_ADDRESS     | ":8081"                     | N/A                               |              Port on which Resubmitter will listen for traffic              | Default: ":8081" |


{{</ tab >}}

{{< tab "Advanced Configuration" >}}

## Advanced Configuration

Below are the additional configuration options offered by the Resubmitter API.

| Variable                    | Example Value               | Possible Values                               |                                   Description                                    | Required         |
|-----------------------------|-----------------------------|-----------------------------------------------|:--------------------------------------------------------------------------------:|------------------|
| MINIMUM_LOG_LEVEL           | "WARN"                      | ["WARN", "ERROR", "INFO"]                     |                         The minimal level used in logs.                          | Default: "INFO"  |
| RSB_META_CAPACITY           | "20000"                     | N/A                                           |    Maximum number of messages which Indexer will return from MongoDB at once     | Default: "10000" |
| RSB_FETCH_CAPACITY          | "200"                       | N/A                                           | Maximum number of workers in Resubmitter that are used for fetching from storage | Default: "100"   |
| RSB_WORKER_NUM              | "3"                         | N/A                                           |       Number of workers in Resubmitter that are used for packaging records       | Default: "2"     |
| RSB_ENABLE_MESSAGE_ORDERING | "false"                     | ["true", "false"]                             |                 Whether to publish messages using ordering keys                  | Default: "false" |
| USE_TLS                     | "false"                     | ["true", "false"]                             |                            Whether to use TLS or not                             | Default: "false" |
| SERVER_TIMEOUT              | "2s"                        | N/A                                           |                The amount of time allowed to read request headers                | Default: "2s"    |

{{</ tab >}}

{{< tab "GCP" >}}

## GCP Configuration

Below are the options to be configured if Google PubSub is used as the destination broker for resubmission and/or Google Cloud Storage is the data source used for the resubmission.

### Common Configuration

| Variable          | Example Value    | Possible Values |      Description      | Required |
|-------------------|------------------|-----------------|:---------------------:|----------|
| PUBSUB_PROJECT_ID | "my-gcp-project" | N/A             | ID of the GCP project | yes      |

### PubSub as Target Broker

| Variable                         | Example Value | Possible Values   |                                                Description                                                 | Required              |
|----------------------------------|---------------|-------------------|:----------------------------------------------------------------------------------------------------------:|-----------------------|
| PUBLISH_TIMEOUT                  | "15s"         | N/A               |               The maximum time that the client will attempt to publish a bundle of messages.               | Default: "15s"        |
| PUBLISH_BYTE_THRESHOLD           | "50"          | N/A               |                         Publish a batch when its size in bytes reaches this value.                         | Default: "50"         |
| PUBLISH_COUNT_THRESHOLD          | "50"          | N/A               |                              Publish a batch when it has this many messages.                               | Default: "50"         |
| PUBLISH_DELAY_THRESHOLD          | "50ms"        | N/A               |                           Publish a non-empty batch after this delay has passed.                           | Default: "50ms"       |
| NUM_PUBLISH_GOROUTINES           | "52428800"    | N/A               | The number of goroutines used in each of the data structures that are involved along the the Publish path. | Default: "52428800"   |
| MAX_PUBLISH_OUTSTANDING_MESSAGES | "800"         | N/A               |             MaxOutstandingMessages is the maximum number of buffered messages to be published.             | Default: "800"        |
| MAX_PUBLISH_OUTSTANDING_BYTES    | "1048576000"  | N/A               |               MaxOutstandingBytes is the maximum size of buffered messages to be published.                | Default: "1048576000" |
| PUBLISH_ENABLE_MESSAGE_ORDERING  | "false"       | ["true", "false"] |                              Whether to publish messages using oredering keys                              | Default: "false"      |

{{</ tab >}}
{{< tab "Azure" >}}

## Azure Configuration

Below are the options to be configured if Azure Service Bus is used as the destination broker for resubmission and/or Azure Blob Storage is the data source used for the resubmission.

### Common Configuration

| Variable            | Example Value                          | Possible Values |               Description               | Required |
|---------------------|----------------------------------------|-----------------|:---------------------------------------:|----------|
| AZURE_CLIENT_ID     | "19b725a4-1a39-5fa6-bdd0-7fe992bcf33c" | N/A             |   Client ID of your Service Principal   | yes      |
| AZURE_TENANT_ID     | "38c345b5-1b40-7fb6-acc0-5ab776daf44e" | N/A             |   Tenant ID of your Service Principal   | yes      |
| AZURE_CLIENT_SECRET | "49d537a6-8a49-5ac7-ffe1-6fe225abe33f" | N/A             | Client secret of your Service Principal | yes      |

### Service Bus as Target Broker

| Variable             | Example Value                                                       | Possible Values |               Description               | Required |
|----------------------|---------------------------------------------------------------------|-----------------|:---------------------------------------:|----------|
| SB_CONNECTION_STRING | "Endpoint=sb://foo.servicebus.windows.net/;SharedAccessKeyName=Roo" | N/A             | Connection string for Azure Service Bus | yes      |

### Azure Blob Storage used as Resubmission Source

| Variable                   | Example Value    | Possible Values |            Description             | Required |
|----------------------------|------------------|-----------------|:----------------------------------:|----------|
| AZURE_STORAGE_ACCOUNT_NAME | mystorageaccount | N/A             | Name of the Azure Storage Account. | yes      |

{{</ tab >}}
{{< tab "Kafka" >}}

## Kafka Configuration

Below are the options to be configured if Apache Kafka is used as the destination broker for resubmission.

### Kafka as Target Broker

| Variable                  | Example Value          | Possible Values   |                                                                 Description                                                                 | Required                        |
|---------------------------|------------------------|-------------------|:-------------------------------------------------------------------------------------------------------------------------------------------:|---------------------------------|
| KAFKA_BROKERS             | "localhost:9092"       | N/A               |                             Comma-separated list of at least one broker which is a member of the target cluster                             | yes                             |
| KAFKA_USE_TLS             | "false"                | ["true", "false"] |                                                          Whether to use TLS or not                                                          | Default: "false"                |
| KAFKA_USE_SASL            | "false"                | ["true", "false"] |                                                         Whether to use SASL or not                                                          | Default: "false"                |
| SASL_USERNAME             | "sasl_user"            | N/A               |                                                                SASL username                                                                | yes if using SASL, otherwise no |
| SASL_PASSWORD             | "sasl_pwd"             | N/A               |                                                                SASL password                                                                | yes if using SASL, otherwise no |
| KAFKA_SKIP_VERIFY         | "false"                | ["true", "false"] |                               Controls whether a client verifies the server's certificate chain and host name                               | Default: "false"                |
| KAFKA_DISABLE_COMPRESSION | "false"                | ["true", "false"] |                                                  Whether to use message compression or not                                                  | Default: "false"                |
| KAFKA_BATCH_SIZE          | "40"                   | N/A               | BatchSize sets the max amount of records the client will buffer, blocking new produces until records are finished if this limit is reached. | Default: "40"                   |
| KAFKA_BATCH_BYTES         | "52428800"             | N/A               |                        BatchBytes parameter controls the amount of memory in bytes that will be used for each batch.                        | Default: "52428800"             |
| KAFKA_BATCH_TIMEOUT       | "10ms"                 | N/A               |                    Linger controls the amount of time to wait for additional messages before sending the current batch.                     | Default: "10ms"                 |
| ENABLE_KERBEROS           | "false"                | ["true", "false"] |                                                      Whether to enable Kerberos or not                                                      | Default: false                  |
| KRB_CONFIG_PATH           | "/path/to/config/file" | N/A               |                                                   Path to the Kerberos configuration file                                                   | yes, if kerberos is enabled     |
| KRB_REALM                 | "REALM.com"            | N/A               |                domain over which a Kerberos authentication server has the authority to authenticate a user, host or service.                | yes, if kerberos is enabled     |
| KRB_SERVICE_NAME          | "kerberos-service"     | N/A               |                                                   Service name we will get a ticket for.                                                    | yes, if kerberos is enabled     |
| KRB_KEY_TAB               | "/path/to/file.keytab" | N/A               |                                                           Path to the keytab file                                                           | yes, if kerberos is enabled     |
| KRB_USERNAME              | "user"                 | N/A               |                                                      Username of the service principal                                                      | yes, if kerberos is enabled     |

{{</ tab >}}
{{</ tabs >}}
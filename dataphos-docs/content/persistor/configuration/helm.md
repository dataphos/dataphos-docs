---
title: "Helm"
draft: false
weight: 2
---

# Configuration

Persistor is deployed as a set of Kubernetes resources, each of which is highly configurable.

The tables below contain the variables that can be configured as part of the Persistor's configuration.

## Persistor Core

Below are the variables used to configure the main Persistor component. The broker-specific configuration options should be taken into consideration along with the "Common" variables.

### Configuration {#reference_persistor_general}

Below is the list of configurable options in the `values.yaml` file.

| Variable              | Type   | Description                                                               | Default                                           |
|-----------------------|--------|---------------------------------------------------------------------------|---------------------------------------------------|
| namespace             | string | The namespace to deploy the Schema Registry into.                         | `dataphos`                                        |
| images                | object | Docker images to use for each of the individual Persistor sub-components. |                                                   |
| images.persistor      | string | The Persistor image.                                                      | `syntioinc/dataphos-persistor-core:1.0.0`         |
| images.indexer        | string | The Indexer image.                                                        | `syntioinc/dataphos-persistor-indexer:1.0.0`      |
| images.indexerApi     | string | The Indexer API image.                                                    | `syntioinc/dataphos-persistor-indexer-api:1.0.0`  |
| images.indexerMongoDb | string | The Mongo image to be used by the indexer.                                | `mongo:4.0`                                       |
| images.resubmitter    | string | The Resubmitter image.        

### Broker Configuration

The `values.yaml` file contains a `brokers` object used to set up the key references to be used by the validators to connect to one or more brokers deemed as part of the overall platform infrastructure.

| Variable                           | Type   | Description                                                                                                        | Applicable If          |
|------------------------------------|--------|--------------------------------------------------------------------------------------------------------------------|------------------------|
| brokers                            | object | The object containing the general information on the brokers the Persistor service(s) will want to associate with. |                        |
| brokers.BROKER_ID                  | object | The object representing an individual broker's configuration.                                                      |                        |
| brokers.BROKER_ID.type             | string | Denotes the broker's type.                                                                                         |                        |
| brokers.BROKER_ID.connectionString | string | The Azure Service Bus Namespace connection string.                                                                 | `type` == `servicebus` |
| brokers.BROKER_ID.projectID        | string | The GCP project ID.                                                                                                | `type` == `pubsub`     |
| brokers.BROKER_ID.brokerAddr       | string | The Kafka bootstrap server address.                                                                                | `type` == `kafka`      |

### Storage Configuration

The `values.yaml` file contains a `storage` object used to set up the key references to be used by the Persistor components to connect to one or more storage destination deemed as part of the overall platform infrastructure.

| Variable                            | Type   | Description                                                                                                                 | Applicable If     |
|-------------------------------------|--------|-----------------------------------------------------------------------------------------------------------------------------|-------------------|
| storage                             | object | The object containing the general information on the storage services the Persistor service(s) will want to associate with. |                   |
| storage.STORAGE_ID                  | object | The object representing an individual storage destination configuration.                                                    |                   |
| storage.STORAGE_ID.type             | string | Denotes the storage type.                                                                                                   |                   |
| storage.STORAGE_ID.accountStorageID | string | The Azure Storage Account name.                                                                                             | `type` == `abs` |
| storage.STORAGE_ID.projectID        | string | The GCP project ID.                                                                                                         | `type` == `gcs`   |


### Indexer Configuration {#reference_indexer}

The `values.yaml` file contains a `indexer` object used to configure one or more indexer components to be deployed as part of the release, explicitly referencing brokers defined in the previous section.

A single "indexer" object is defined as a set of a **database**, the **API exposing data in that database** and a **consumer component** responsible for pulling the indexer metadata into that database.

| Variable                             | Type    | Description                                                                                                                                                        | Default     | Applicable If                        |
|--------------------------------------|---------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|--------------------------------------|
| indexer                              | object  | The object containing the information on all of the indexer(s) to be deployed as part of the Helm installation.                                                    |             |                                      |
| indexer.IDX_ID                       | object  | The object representing the individual indexer's configuration.                                                                                                    |             |                                      |
| indexer.IDX_ID.broker                | string  | Reference to the broker the indexer metadata is retrieved from.                                                                                                    |             |                                      |
| indexer.IDX_ID.topic                 | string  | The topic the indexer metadata are pulled from.                                                                                                                    |             |                                      |
| indexer.IDX_ID.consumerID            | string  | The consumer identifier (subscription, consumer group, etc.)                                                                                                       |             |                                      |
| indexer.IDX_ID.deadletterTopic       | string  | The name of the dead-letter topic used for failed data processing. If not set, dead-lettering is disabled (must be enabled if `indexer.IDX_ID.broker` == `kafka`). |             |                                      |
| indexer.IDX_ID.batchSize             | string  | Maximum number of messages in a batch.                                                                                                                             | `"10000"`   |                                      |
| indexer.IDX_ID.batchMemory           | string  | Maximum bytes in batch.                                                                                                                                            | `"1000000"` |                                      |
| indexer.IDX_ID.batchTimeout          | string  | Time to wait before writing batch if it is not full.                                                                                                               | `30s`       |                                      |
| indexer.IDX_ID.replicas              | integer | The number of replicas of the indexer API microservice.                                                                                                            |             |                                      |
| indexer.IDX_ID.consumerReplicas      | integer | The number of replicas of a given indexer instance to pull/process messages simultaneously.                                                                        |             |                                      |
| indexer.IDX_ID.storageSize           | string  | The size of the Indexer's underlying Mongo storage.                                                                                                                |             |                                      |
| indexer.IDX_ID.mongoConnectionString | string  | An optional MongoDB connection string if using an external database. If this value is not set, a MongoDB instance will be deployed on the same cluster.            |             |                                      |
| indexer.IDX_ID.serviceAccountSecret  | string  | The reference to a secret that contains a `key.json` key and the contents of a Google Service Account JSON file as its contents.                                   |             | `brokers.BROKER_ID.type` == `pubsub` |
| indexer.IDX_ID.serviceAccountKey     | string  | A Google Service Account private key in JSON format, base64 encoded. Used to create a new `serviceAccountSecret` secret, if provided.                              |             | `brokers.BROKER_ID.type` == `pubsub` |


### Resubmitter Configuration {#reference_resubmitter}

The `values.yaml` file contains a `resubmitter` object used to configure one or more resubmitter components to be deployed as part of the release, explicitly referencing brokers, indexer and storage objects defined in the previous section.

| Variable                                 | Type   | Description                                                                                                                           | Applicable If                                                                  |
|------------------------------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------|
| resubmitter                              | object | The object containing the information on all of the resubmitter services to be deployed as part of the Helm installation.             |                                                                                |
| resubmitter.RSMB_ID                      | object | The object representing the individual resubmitter's configuration.                                                                   |                                                                                |
| resubmitter.RSMB_ID.broker               | string | Reference to the broker resubmitted messages will be sent to.                                                                         |                                                                                |
| resubmitter.RSMB_ID.storage              | string | Reference to the storage the resubmitter service can connect to.                                                                      |                                                                                |
| resubmitter.RSMB_ID.indexer              | string | The indexer instance whose API will be used to query the needed metadata.                                                             |                                                                                |
| resubmitter.RSMB_ID.clientID             | string | The Client ID of the Azure Service Principal with the required role assignments.                                                      | `brokers.BROKER_ID.type` == `servicebus` or `storage.STORAGE_ID.type` == `abs` |
| resubmitter.RSMB_ID.clientSecret         | string | The Client Secret of the Azure Service Principal with the required role assignments.                                                  | `brokers.BROKER_ID.type` == `servicebus` or `storage.STORAGE_ID.type` == `abs` |
| resubmitter.RSMB_ID.tenantID             | string | The Tenant ID of the Azure Service Principal with the required role assignments.                                                      | `brokers.BROKER_ID.type` == `servicebus` or `storage.STORAGE_ID.type` == `abs` |
| resubmitter.RSMB_ID.serviceAccountSecret | string | The reference to a secret that contains a `key.json` key and the contents of a Google Service Account JSON file as its contents.      | `brokers.BROKER_ID.type` == `pubsub` or `storage.STORAGE_ID.type` == `gcs`     |
| resubmitter.RSMB_ID.serviceAccountKey    | string | A Google Service Account private key in JSON format, base64 encoded. Used to create a new `serviceAccountSecret` secret, if provided. | `brokers.BROKER_ID.type` == `pubsub` or `storage.STORAGE_ID.type` == `gcs`     |


### Persistor Configuration {#reference_persistor}
The `values.yaml` file contains a `persistor` object used to configure one or more Persistor components to be deployed as part of the release, explicitly referencing the objects defined as part of the previous section.

| Variable                              | Type   | Description                                                                                                                                                                                                                                | Default               | Applicable If                                                                  |
|---------------------------------------|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------|--------------------------------------------------------------------------------|
| persistor                             | object | The object containing the information on all of the Persistors to be deployed as part of the Helm installation.                                                                                                                            |                       |                                                                                |
| persistor.PES_ID                      | object | The object representing the individual Persistor's configuration.                                                                                                                                                                          |                       |                                                                                |
| persistor.PES_ID.broker               | string | Reference to the broker messages are pulled from.                                                                                                                                                                                          |                       |                                                                                |
| persistor.PES_ID.topic                | string | The topic the messages are pulled from.                                                                                                                                                                                                    |                       |                                                                                |
| persistor.PES_ID.consumerID           | string | The consumer identifier (subscription, consumer group, etc)                                                                                                                                                                                |                       |                                                                                |
| persistor.PES_ID.storage              | string | The reference to the storage messages will be persisted to.                                                                                                                                                                                |                       |                                                                                |
| persistor.PES_ID.indexer              | string | The reference to the indexer the Persistor is tied to. If not set, the Indexer plugin is disabled.                                                                                                                                         |                       |                                                                                |
| persistor.PES_ID.storageTargetID      | string | The identifier of the storage container (bucket) to store the data to.                                                                                                                                                                     |                       |                                                                                |
| persistor.PES_ID.deadletterBroker     | string | Optional reference to the broker containing the dead-letter topic. If the Indexer plugin is enabled, `indexer.broker` is used instead and this value is ignored. Required if the Indexer plugin is disabled and dead-lettering is enabled. |                       |                                                                                |
| persistor.PES_ID.deadletterTopic      | string | The name of the dead-letter topic used for failed data processing. If not set, dead-lettering is disabled (must be enabled if kafka broker is used).                                                                                       |                       |                                                                                |
| persistor.PES_ID.batchSize            | string | Maximum number of messages in a batch.                                                                                                                                                                                                     | `"10000"`             |                                                                                |
| persistor.PES_ID.batchMemory          | string | Maximum bytes in batch.                                                                                                                                                                                                                    | `"1000000"`           |                                                                                |
| persistor.PES_ID.batchTimeout         | string | Time to wait before writing batch if it is not full.                                                                                                                                                                                       | `30s`                 |                                                                                |
| persistor.PES_ID.storagePrefix        | string | Prefix to be given to all files stored to the chosen target blob storage.                                                                                                                                                                  | `msg`                 |                                                                                |
| persistor.PES_ID.storageVersionKey    | string | Key in metadata that messages get grouped by.                                                                                                                                                                                              |                       |                                                                                |
| persistor.PES_ID.storageMask          | string | Structure of the path under which batches are stored.                                                                                                                                                                                      | `year/month/day/hour` |                                                                                |
| persistor.PES_ID.storageCustomValues  | string | Comma-separated list of key:value pairs to include in the file path. If the file path contains `key1:value1` and `STORAGE_MASK` contains `key1`, then the path will contain `value1`.                                                      |                       |                                                                                |
| persistor.PES_ID.replicas             | string | The number of replicas of a given Persistor instance to pull/process messages simultaneously.                                                                                                                                              |                       |                                                                                |
| persistor.PES_ID.clientID             | string | The Client ID of the Azure Service Principal with the required role assignments.                                                                                                                                                           |                       | `brokers.BROKER_ID.type` == `servicebus` or `storage.STORAGE_ID.type` == `abs` |
| persistor.PES_ID.clientSecret         | string | The Client Secret of the Azure Service Principal with the required role assignments.                                                                                                                                                       |                       | `brokers.BROKER_ID.type` == `servicebus` or `storage.STORAGE_ID.type` == `abs` |
| persistor.PES_ID.tenantID             | string | The Tenant ID of the Azure Service Principal with the required role assignments.                                                                                                                                                           |                       | `brokers.BROKER_ID.type` == `servicebus` or `storage.STORAGE_ID.type` == `abs` |
| persistor.PES_ID.serviceAccountSecret | string | The reference to a secret that contains a `key.json` key and the contents of a Google Service Account JSON file as its contents.                                                                                                           |                       | `brokers.BROKER_ID.type` == `pubsub` or `storage.STORAGE_ID.type` == `gcs`     |
| persistor.PES_ID.serviceAccountKey    | string | A Google Service Account private key in JSON format, base64 encoded. Used to create a new `serviceAccountSecret` secret, if provided.                                                                                                      |                       | `brokers.BROKER_ID.type` == `pubsub` or `storage.STORAGE_ID.type` == `gcs`     |


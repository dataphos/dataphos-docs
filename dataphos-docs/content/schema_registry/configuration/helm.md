---
title: "Helm"
draft: false
weight: 2
---

# Dataphos Schema Registry

The Helm Chart for the Dataphos Schema Registry component.

## Configuration {#reference_schema_registry}

Below is the list of configurable options in the `values.yaml` file.

| Variable                    | Type    | Description                                                                     | Default                                                   |
|-----------------------------|---------|---------------------------------------------------------------------------------|-----------------------------------------------------------|
| namespace                   | string  | The namespace to deploy the Schema Registry into.                               | `dataphos`                                                |
| images                      | object  | Docker images to use for each of the individual Schema Registry sub-components. |                                                           |
| images.initdb               | string  | Initdb Docker image.                                                            | `syntioinc/dataphos-schema-registry-initdb:1.0.0`         |
| images.registry             | string  | The Schema Registry image.                                                      | `syntioinc/dataphos-schema-registry-api:1.0.0`            |
| images.compatibilityChecker | string  | The compatibility checker image.                                                | `syntioinc/dataphos-schema-registry-compatibility:1.0.0`  |
| images.validityChecker      | string  | Validity Checker image.                                                         | `syntioinc/dataphos-schema-registry-validity:1.0.0`       |
| registryReplicas            | integer | The number of replicas of the Schema Registry service.                          | `1`                                                       |
| registrySvcName             | string  | The name of the Schema Registry service.                                        | `schema-registry-svc`                                     |
| database                    | object  | The Schema History database configuration object.                               |                                                           |
| database.name               | string  | History database name.                                                          | `postgres`                                                |
| database.username           | string  | History database username.                                                      | `postgres`                                                |
| database.password           | string  | History database password.                                                      | `POSTGRES_PASSWORD`                                       |


# Dataphos Schema Validator {#reference_schema_validator}

The Helm Chart for the Dataphos Validator component.

## Configuration

Below is the list of configurable options in the `values.yaml` file.

| Variable              | Type    | Description                                                                     | Default                                                |
|-----------------------|---------|---------------------------------------------------------------------------------|--------------------------------------------------------|
| namespace             | string  | The namespace to deploy the Schema Registry into.                               | `dataphos`                                             |
| images                | object  | Docker images to use for each of the individual Schema Registry sub-components. |                                                        |
| images.validator      | string  | The Validator image.                                                            | `syntioinc/dataphos-schema-registry-validator:1.0.0`   |
| images.xmlValidator   | string  | The XML Validator image.                                                        | `syntioinc/dataphos-schema-registry-xml-val:1.0.0`     |
| images.csvValidator   | string  | The CSV validator image.                                                        | `syntioinc/dataphos-schema-registry-csv-val:1.0.0`     |
| xmlValidator          | object  | The XML Validator configuration.                                                |                                                        |
| xmlValidator.enable   | boolean | Determines whether the XML validator should be enabled.                         | `true`                                                 |
| xmlValidator.replicas | integer | The number of XML Validator replicas.                                           | `1`                                                    |
| csvValidator          | object  | The CSV Validator configuration.                                                |                                                        |
| csvValidator.enable   | boolean | Determines whether the CSV validator should be enabled.                         | `true`                                                 |
| csvValidator.replicas | integer | The number of CSV Validator replicas.                                           | `1`                                                    |
| schemaRegistryURL     | string  | The link to the Schema Registry component.                                      | `http://schema-registry-svc:8080`                      |

### Broker Configuration

The `values.yaml` file contains a `brokers` object used to set up the key references to be used by the validators to
connect to one or more brokers deemed as part of the overall platform infrastructure.

| Variable                           | Type   | Description                                                                                                     | Applicable If          |
|------------------------------------|--------|-----------------------------------------------------------------------------------------------------------------|------------------------|
| brokers                            | object | The object containing the general information on the brokers the validator service will want to associate with. |                        |
| brokers.BROKER_ID                  | object | The object representing an individual broker's configuration.                                                   |                        |
| brokers.BROKER_ID.type             | string | Denotes the broker's type.                                                                                      |                        |
| brokers.BROKER_ID.connectionString | string | The Azure Service Bus Namespace connection string.                                                              | `type` == `servicebus` |
| brokers.BROKER_ID.projectID        | string | The GCP project ID.                                                                                             | `type` == `pubsub`     |
| brokers.BROKER_ID.brokerAddr       | string | The Kafka bootstrap server address.                                                                             | `type` == `kafka`      |

### Validator Configuration {#reference_validator}

The `values.yaml` file contains a `validator` object used to configure one or more validators to be deployed as part of
the release, explicitly referencing brokers defined in the previous section.

| Variable                              | Type   | Description                                                                                                                           | Applicable If                        |
|---------------------------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| validator                             | object | The object containing the information on all of the validators to be deployed as part of the Helm installation.                       |                                      |
| validator.VAL_ID                      | object | The object representing the individual validator's configuration.                                                                     |                                      |
| validator.VAL_ID.broker               | string | Reference to the broker messages are pulled FROM.                                                                                     |                                      |
| validator.VAL_ID.destinationBroker    | string | Reference to the broker messages are sent TO.                                                                                         |                                      |
| validator.VAL_ID.topic                | string | The topic the messages are pulled FROM.                                                                                               |                                      |
| validator.VAL_ID.consumerID           | string | The consumer identifier (subscription, consumer group, etc).                                                                          |                                      |
| validator.VAL_ID.validTopic           | string | The topic VALID messages are sent TO.                                                                                                 |                                      |
| validator.VAL_ID.deadletterTopic      | string | The topic INVALID messages are sent TO.                                                                                               |                                      |
| validator.VAL_ID.replicas             | string | The number of replicas of a given validator instance to pull/process messages simultaneously.                                         |                                      |
| validator.VAL_ID.serviceAccountSecret | string | The reference to a secret that contains a `key.json` key and the contents of a Google Service Account JSON file as its contents.      | `brokers.BROKER_ID.type` == `pubsub` |
| validator.VAL_ID.serviceAccountKey    | string | A Google Service Account private key in JSON format, base64 encoded. Used to create a new `serviceAccountSecret` secret, if provided. | `brokers.BROKER_ID.type` == `pubsub` |
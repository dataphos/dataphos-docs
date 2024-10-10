---
title: "Shell"
draft: false
weight: 1
---

# Schema Registry Configuration

The **Schema Registry server** may be deployed following the same steps as outlined on the [quickstart](/schema_registry/quickstart) page. There are no additional configuration options required beyond deploying the microservices and configuring the credentials of the schema history database.

## Validator Configuration

The **Validator** component of the Schema Registry is a single Docker image configured through a set of environment variables. The tables below cover the core configuration variables, outlining how the different combinations of producers and consumers can be configured.

The tables are organized by the message broker technology, listing which variables need to be set when pulling data from the given broker type and when publishing data to the given broker type. If, for instance, you wish to pull and validate data from **Kafka** and publish the results to **GCP Pub/Sub**, you would read the **Consumer** section from the **Kafka** tab, and then the **Producer** section of the **GCP Pub/Sub** tab.

> **NOTE**: Values with the "*" sign in the following tables are required and need to be set!

{{< tabs "Configuration" >}}
{{< tab "Common Configuration" >}}

## Common configuration

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| CONSUMER_TYPE*                                     |Type of broker to consume messages from.| string |              |
| PRODUCER_TYPE*                                    |Type of broker to deliver valid and invalid messages to. | string        |              |
| TOPICS_VALID*                                      |Topic or ID where valid messages are published to.| string |              |
| TOPICS_DEAD_LETTER*                                |Topic or ID where invalid messages are published to.| string |              |
| REGISTRY_URL*                                      |Address of the Schema Registry (If deployed in the same namespace as the **Registry** component it can stay http://schema-registry-svc.com as the local DNS name of the service)| string |  http://schema-registry-svc.com            |
| REGISTRY_GET_TIMEOUT                               |Interval to wait for the fetch request response.| time.Duration | 4s |
| REGISTRY_REGISTER_TIMEOUT                          |Interval to wait for the register request response.| time.Duration | 10s |
| REGISTRY_UPDATE_TIMEOUT                            |Interval to wait for the update request response.| time.Duration | 10s |
| REGISTRY_INMEM_CACHE_SIZE                          |Cache size for the fetched schemas.| int | 100 |
| VALIDATORS_ENABLE_CSV                              |Enable CSV validation.| bool | false |
| VALIDATORS_ENABLE_JSON                             |Enable JSON validation.| bool | false |
| VALIDATORS_ENABLE_AVRO                             |Enable  avro validation.| bool | false |
| VALIDATORS_ENABLE_PROTOBUF                         |Enable  protobuf validation.| bool | false |
| VALIDATORS_ENABLE_XML                              |Enable  XML validation.| bool | false |
| VALIDATORS_CSV_URL                                 |Address of the CSV validator.| string |   http://csv-validator-svc.com         |
| VALIDATORS_CSV_TIMEOUT_BASE                        |Interval to wait for connecting to the CSV validator.| time.Duration | 2s |
| VALIDATORS_JSON_USE_ALT_BACKEND                    |Use another library for validation (gojsonschema instead of jsonschema).| bool | false              |
| VALIDATORS_JSON_CACHE_SIZE                         |Size of the JSON validator cache.| int | 100          |
| VALIDATORS_PROTOBUF_FILE_PATH                      |File path to the .proto file.| string | “./.schemas” |
| VALIDATORS_PROTOBUF_CACHE_SIZE                     |Protobuf validator cache size.| int | 100          |
| VALIDATORS_XML_URL                                 |Address of the XML validator.| string |   http://csv-validator-svc.com            |
| VALIDATORS_XML_TIMEOUT_BASE                        |Interval to wait for connecting to the XML validator.| time.Duration | 3s |

{{< /tab >}}
{{< tab "Additional Configuration" >}}

## Additional Configuration

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| SHOULD_LOG_MISSING_SCHEMA                          |Log a warning if a message is missing a schema.| bool | false |
| SHOULD_LOG_VALID                                   |Log an information if a message is classified as valid.| bool          | false |
| SHOULD_LOG_DEAD_LETTER                             |Log an error if a message is classified as deadletter.| bool | false |
| RUN_OPTIONS_ERR_THRESHOLD                          |The acceptable amount of unrecoverable message processing errors per RUN_OPTIONS_ERR_INTERVAL. If the threshold is reached, a run is preemptively canceled. A non-positive value is ignored.| int64         | 50           |
| RUN_OPTIONS_ERR_INTERVAL                           |The time interval used to reset the RUN_OPTIONS_ERR_THRESHOLD counter. If no change to the counter is observed in this interval, the counter is reset, as it's safe to assume the system has managed to recover from the erroneous behavior. Only used if RUN_OPTIONS_ERR_THRESHOLD is a positive integer.| time.Duration | 1m           |
| RUN_OPTIONS_NUM_RETRIES                            |Determines the number of times the executor will repeat erroneous calls to the handler. Keep in mind this may result in duplicates if the messaging system re-sends messages on acknowledgment timeout. Setting this option will lead record-based executors to stop polling for new messages until the ones which are currently being retry-ed are either successful or the number of retries exceeds NumRetries.| int           | 0            |
| NUM_SCHEMA_COLLECTORS                              |Defines the maximum amount of inflight requests to the schema registry.| int           | -1           |
| NUM_INFERRERS                                      |Defines the maximum amount of inflight destination topic inference jobs (validation and routing).| int           | -1           |
| METRICS_LOGGING_INTERVAL                           |Defines how often the metrics are going to be logged.| time.Duration | 5s           |

{{< /tab >}}

{{< tab "Kafka" >}}

## Kafka Consumer

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| CONSUMER_KAFKA_ADDRESS*                           |Comma-separated list of at least one broker which is a member of the target cluster.| string |              |
| CONSUMER_KAFKA_TOPIC*                             |Name of the topic from which the Validator component will consume the messages.| string |              |
| CONSUMER_KAFKA_GROUP_ID*                          |Determines which consumer group the consumer belongs to.| string |              |
| CONSUMER_KAFKA_<br>TLS_CONFIG_CLIENT_KEY_FILE          |Path to the client TLS key file.| string |              |
| CONSUMER_KAFKA_<br>TLS_CONFIG_CA_CERT_FILE             |Path to the CA TLS certificate file.| string |              |
| CONSUMER_KAFKA_SETTINGS_<br>MAX_BYTES                  |The maximum amount of bytes Kafka will return whenever the consumer polls a broker. It is used to limit the size of memory that the consumer will use to store data that was returned from the server, irrespective of how many partitions or messages were returned. | int | 10485760     |
| CONSUMER_KAFKA_SETTINGS_<br>MAX_CONCURRENT_FETCHES     |The maximum number of fetch requests to allow in flight or buffered at once. This setting, paired with CONSUMER_KAFKA_SETTINGS_MAX_BYTES, can upper bound the maximum amount of memory that the client can use for consuming. Requests are issued to brokers in a FIFO order: once the client is ready to issue a request to a broker, it registers that request and issues it in order with other registrations. <br>A value of 0 implies the allowed concurrency is unbounded and will be limited only by the number of brokers in the cluster.| int | 3            |
| CONSUMER_KAFKA_SETTINGS_<br>MAX_POLL_RECORDS           |The maximum number of records that a single call to poll() will return. Use this to control the amount of data (but not the size of data) your application will need to process in one iteration. Keep in mind that this is only the maximum number of records; there's no guarantee the BatchIterator will return CONSUMER_KAFKA_SETTINGS_MAX_POLL_RECORDS even if the state of the topic the iterator consumes from allows it.| int | 100          |

## Kafka Producer

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| PRODUCER_KAFKA_ADDRESS*                           |Comma-separated list of at least one broker which is a member of the target cluster.| string        |              |
| PRODUCER_KAFKA_<br>TLS_CONFIG_ENABLED                  |Address of the Kafka producer server.| bool          | false        |
| PRODUCER_KAFKA_<br>TLS_CONFIG_CLIENT_CERT_FILE**         |Path to the client TLS certificate file.| string        |              |
| PRODUCER_KAFKA_<br>TLS_CONFIG_CLIENT_KEY_FILE**         |Path to the client TLS key file.| string        |              |
| PRODUCER_KAFKA_<br>TLS_CONFIG_CA_CERT_FILE**             |Path to the CA TLS certificate file.| string        |              |
| PRODUCER_KAFKA_SETTINGS_<br>BATCH_SIZE                 |The max amount of records the client will buffer, blocking new produces until records are finished if this limit is reached.| int           | 40           |
| PRODUCER_KAFKA_SETTINGS_<br>BATCH_BYTES                |When multiple records are sent to the same partition, the producer will batch them together. This parameter controls the amount of memory in bytes that will be used for each batch. <br><br>This does not mean that the producer will wait for the batch to become full. The producer will send half-full batches and even batches with just a single message in them. Therefore, setting the batch size too large will not cause delays in sending messages; it will just use more memory for the batches.| int64         | 5242880      |
| PRODUCER_KAFKA_SETTINGS_<br>LINGER                     |The amount of time to wait for additional messages before sending the current batch. The producer sends a batch of messages either when the current batch is full or when the Linger limit is reached, whatever comes first. This variable is specific to a topic partition. A high volume producer will likely be producing to many partitions; it is both unnecessary to linger in this case and inefficient because the client will have many timers running (and stopping and restarting) unnecessarily.| time.Duration | 10ms         |

{{< /tab >}}

{{< tab "Event Hubs" >}}

## EventHubs Consumer

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| CONSUMER_EVENTHUBS_ADDRESS*                       |Address of the Event Hubs server.| string |              |
| CONSUMER_EVENTHUBS_TOPIC*                         |Name of the topic from which the Validator component will consume the messages.| string |              |
| CONSUMER_EVENTHUBS_GROUP_ID*                      |Determines which group the consumer belongs to.| string |              |
| CONSUMER_EVENTHUBS_<br>TLS_CONFIG_CLIENT_KEY_FILE      |Path to the client TLS key file.| string        |              |
| CONSUMER_EVENTHUBS_<br>TLS_CONFIG_CA_CERT_FILE         |Path to the CA TLS certificate file.| string        |              |
| CONSUMER_EVENTHUBS_<br>SASL_CONFIG_USER*              |SASL username.| string        |              |
| CONSUMER_EVENTHUBS_<br>SASL_CONFIG_PASSWORD*          |SASL password.| string        |              |
| CONSUMER_EVENTHUBS_SETTINGS_<br>MAX_BYTES              |The maximum amount of bytes Kafka will return whenever the consumer polls a broker. It is used to limit the size of memory that the consumer will use to store data that was returned from the server, irrespective of how many partitions or messages were returned.| int           | 10485760     |
| CONSUMER_EVENTHUBS_SETTINGS_<br>MAX_CONCURRENT_FETCHES |The maximum number of fetch requests to allow in flight or buffered at once. This setting, paired with CONSUMER_KAFKA_SETTINGS_MAX_BYTES, can upper bound the maximum amount of memory that the client can use for consuming. Requests are issued to brokers in a FIFO order: once the client is ready to issue a request to a broker, it registers that request and issues it in order with other registrations. <br>A value of 0 implies the allowed concurrency is unbounded and will be limited only by the number of brokers in the cluster.| int           | 3            |
| CONSUMER_EVENTHUBS_SETTINGS_<br>MAX_POLL_RECORDS       |The maximum number of records that a single call to poll() will return. Use this to control the amount of data (but not the size of data) your application will need to process in one iteration. Keep in mind that this is only the maximum number of records; there's no guarantee the BatchIterator will return CONSUMER_KAFKA_SETTINGS_MAX_POLL_RECORDS even if the state of the topic the iterator consumes from allows it.| int           | 100          |

## EventHubs Producer

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| PRODUCER_EVENTHUBS_ADDRESS*                       |Address of the Event Hubs producer server.| string        |              |
|<br>| <br> | <br> | <br> |
| PRODUCER_EVENTHUBS_<br>TLS_CONFIG_CLIENT_KEY_FILE      |Path to the client TLS key file.| string        |              |
| PRODUCER_EVENTHUBS_<br>TLS_CONFIG_CA_CERT_FILE         |Path to the CA TLS certificate file.| string        |              |
| PRODUCER_EVENTHUBS_<br>SASL_CONFIG_USER*              |SASL username.| string        |              |
| PRODUCER_EVENTHUBS_<br>SASL_CONFIG_PASSWORD*          |SASL password.| string        |              |
|<br>| <br> | <br> | <br> |
| PRODUCER_EVENTHUBS_SETTINGS_<br>BATCH_SIZE             |The max amount of records the client will buffer, blocking new produces until records are finished if this limit is reached.| int           | 40           |
| PRODUCER_EVENTHUBS_SETTINGS_<br>BATCH_BYTES            |When multiple records are sent to the same partition, the producer will batch them together. This parameter controls the amount of memory in bytes that will be used for each batch. This does not mean that the producer will wait for the batch to become full. The producer will send half-full batches and even batches with just a single message in them. Therefore, setting the batch size too large will not cause delays in sending messages; it will just use more memory for the batches.| int64         | 5242880      |
| PRODUCER_EVENTHUBS_SETTINGS_<br>LINGER                 |The amount of time to wait for additional messages before sending the current batch. The producer sends a batch of messages either when the current batch is full or when the Linger limit is reached, whatever comes first. This variable is specific to a topic partition. A high volume producer will likely be producing to many partitions; it is both unnecessary to linger in this case and inefficient because the client will have many timers running (and stopping and restarting) unnecessarily.| time.Duration | 10ms         |

{{< /tab >}}

{{< tab "GCP Pub/Sub" >}}

## Pub/Sub Consumer

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| CONSUMER_PUBSUB_PROJECT_ID*                       |ID of the GCP project where Pub/Sub consumer is running.| string        |              |
| CONSUMER_PUBSUB_SUBSCRIPTION_ID*                  |Subscription ID of the topic from which the Validator component will consume the messages. | string        |              |
| CONSUMER_PUBSUB_SETTINGS_<br>MAX_EXTENSION             |The maximum period for which the Subscription should automatically extend the ack deadline for each message. The Subscription will automatically extend the ack deadline of all fetched Messages up to the duration specified. Automatic deadline extension beyond the initial receipt may be disabled by specifying a duration less than 0.| time.Duration | 30m          |
| CONSUMER_PUBSUB_SETTINGS_<br>MAX_EXTENSION_PERIOD      |The maximum duration by which to extend the ack deadline at a time. The ack deadline will continue to be extended by up to this duration until CONSUMER_PUBSUB_SETTINGS_MAX_EXTENSION is reached. Setting this variable bounds the maximum amount of time before a message redelivery in the event the subscriber fails to extend the deadline. CONSUMER_PUBSUB_SETTINGS_MAX_EXTENSION_PERIOD must be between 10s and 600s (inclusive). This configuration can be disabled by specifying a duration less than (or equal to) 0.| time.Duration | 3m           |
| CONSUMER_PUBSUB_SETTINGS_<br>MAX_OUTSTANDING_MESSAGES  |The maximum number of unprocessed messages (unacknowledged but not yet expired). If this variable is 0, default value will be taken. If the value is negative, then there will be no limit on the number of unprocessed messages.| int           | 1000         |
| CONSUMER_PUBSUB_SETTINGS_<br>MAX_OUTSTANDING_BYTES     |The maximum size of unprocessed messages (unacknowledged but not yet expired). If MaxOutstandingBytes is 0, it will be treated as if it were DefaultReceiveSettings.MaxOutstandingBytes. If the value is negative, then there will be no limit on the number of bytes for unprocessed messages.| int           | 419430400    |
| CONSUMER_PUBSUB_SETTINGS_<br>NUM_GOROUTINES            |The number of goroutines that each data structure along the Receive path will spawn.| int           | 10           |

## Pub/Sub Producer

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| PRODUCER_PUBSUB_PROJECT_ID*                       |ID of the GCP project where Pub/Sub producer is running.| string        |              |
| PRODUCER_PUBSUB_SETTINGS_<br>DELAY_THRESHOLD           |Publish a non-empty batch after this delay has passed.| time.Duration | 50ms         |
| PRODUCER_PUBSUB_SETTINGS_<br>COUNT_THRESHOLD           |Publish a batch when it has this many messages.| int           | 50           |
| PRODUCER_PUBSUB_SETTINGS_<br>BYTE_THRESHOLD            |Publish a batch when its size in bytes reaches this value.| int           | 52428800     |
| PRODUCER_PUBSUB_SETTINGS_<br>NUM_GOROUTINES            |The number of goroutines used in each of the data structures that are involved along the the Publish path. Adjusting this value adjusts concurrency along the publish path.| int           | 5            |
| PRODUCER_PUBSUB_SETTINGS_<br>MAX_OUTSTANDING_MESSAGES  |The maximum number of buffered messages to be published. If less than or equal to zero, this is disabled.| int           | 800          |
| PRODUCER_PUBSUB_SETTINGS_<br>MAX_OUTSTANDING_BYTES     |The maximum size of buffered messages to be published. If less than or equal to zero, this is disabled.| int           | 1048576000   |
| PRODUCER_PUBSUB_SETTINGS_<br>ENABLE_MESSAGE_ORDERING   |Enables delivery of ordered keys.| bool          | false        |

{{< /tab >}}

{{< tab "Service Bus" >}}

## Service Bus Consumer

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| CONSUMER_SERVICEBUS_CONNECTION_STRING*            |Service Bus consumer connection string.| string        |              |
| CONSUMER_SERVICEBUS_TOPIC*                        |Name of the topic from which the Validator component will consume the messages.| string        |              |
| CONSUMER_SERVICEBUS_SUBSCRIPTION*                 |Service Bus subscription.| string        |              |
| CONSUMER_SERVICEBUS_SETTINGS_<br>BATCH_SIZE            |Size of the consumer Service Bus batches.| int           | 100          |
| CONSUMER_SERVICEBUS_SETTINGS_<br>BATCH_TIMEOUT         |(MOZDA DEPRECATED??)| time.Duration | 500ms        |

## Servic eBus Producer

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| PRODUCER_SERVICEBUS_<br>CONNECTION_STRING*            |Service Bus producer connection string.| string        |              |

{{< /tab >}}

{{< tab "NATS JetStream" >}}

## NATS JetStream Consumer

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| CONSUMER_JETSTREAM_URL*                           |JetStream consumer url.| string        |              |
| CONSUMER_JETSTREAM_SUBJECT*                       |Subject from which the Validator component will consume the messages.| string        |              |
| CONSUMER_JETSTREAM_CONSUMER_NAME*                 |JetStream consumer name.| string        |              |
| CONSUMER_JETSTREAM_SETTINGS_<br>BATCH_SIZE             |Size of the consumer JetStream batches.| int           | 100          |
| CONSUMER_JETSTREAM_SETTINGS_<br>BATCH_TIMEOUT          |(MOZDA DEPRECATED??)| time.Duration | 500ms        |

## NATS JetStream Producer

|              Environment variable name             | Description |      Type     |    Default   |
|:--------------------------------------------------:|-------------|:-------------:|:------------:|
| PRODUCER_JETSTREAM_URL*                           |JetStream producer url.| string        |              |
| PRODUCER_JETSTREAM_SETTINGS_<br>MAX_INFLIGHT_PENDING   |Specifies the maximum outstanding async publishes that can be inflight at one time.| int           | 512          |

{{< /tab >}}
{{< /tabs >}}



---
title: "Overview"
draft: false 
weight: 1
---

![](/sr.png)

**Dataphos Schema Registry** is a cloud-based schema management and message validation system. 

Schema management consists of schema registration and versioning, and message validation consists of validators that validate messages for
the given message schema. Its core components are a server with HTTP RESTful interface used to manage the schemas, and 
lightweight message validators, which verify the schema compatibility and validity of the incoming messages. 

The system allows developers to define and manage standard schemas for events, sharing them across the organization and safely 
evolving them with the preservation of compatibility as well as validating events with a given event schema. 
The Schema Registry component stores a versioned history of all schemas and provides a RESTful interface for working with them.

## What is a schema?

In the context of a schema registry, a schema is a formal definition of the structure and data types for a particular
data format. The schema defines the rules that govern how data is represented and what values are allowed for each
field.

For example, if you have a dataset that contains customer information, you might define a schema for that dataset that
specifies the fields that must be present (e.g. name, address, phone number), the data types for each field
(e.g. string, integer, date), and any constraints or rules that apply to the data (e.g. phone numbers must be in a
particular format).

The schema itself is typically defined using a specific schema language, such as Avro, JSON Schema, Protobuf, etc. The
schema language provides a standardized syntax for defining the schema, which can be used by different systems to ensure
that they're interpreting the schema correctly.

### Schema Examples

**Example 1**

{{< tabs "Schema Example 1" >}} {{< tab "Message" >}}
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "age": 21
}

```
{{< /tab >}}
{{< tab "Schema" >}}
```json
{
  "$id": "https://example.com/person.schema.json",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Person",
  "type": "object",
  "properties": {
    "firstName": {
      "type": "string",
      "description": "The person's first name."
    },
    "lastName": {
      "type": "string",
      "description": "The person's last name."
    },
    "age": {
      "description": "Age in years which must be equal to or greater than zero.",
      "type": "integer",
      "minimum": 0
    }
  }
}

```
{{< /tab >}}
{{< /tabs>}}

**Example 2**
{{< tabs "Schema Example 2" >}} {{< tab "Message" >}}
```json
{
  "id": 7,
  "name": "John Doe",
  "age": 22,
  "hobbies": {
    "indoor": [
      "Chess"
    ],
    "outdoor": [
      "BasketballStand-up Comedy"
    ]
  }
}
```
{{< /tab >}}
{{< tab "Schema" >}}
```json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "$id": "https://example.com/employee.schema.json",
  "title": "Record of employee",
  "description": "This document records the details of an employee",
  "type": "object",
  "properties": {
    "id": {
      "description": "A unique identifier for an employee",
      "type": "number"
    },
    "name": {
      "description": "Full name of the employee",
      "type": "string"
    },
    "age": {
      "description": "Age of the employee",
      "type": "number"
    },
    "hobbies": {
      "description": "Hobbies of the employee",
      "type": "object",
      "properties": {
        "indoor": {
          "type": "array",
          "items": {
            "description": "List of indoor hobbies",
            "type": "string"
          }
        },
        "outdoor": {
          "type": "array",
          "items": {
            "description": "List of outdoor hobbies",
            "type": "string"
          }
        }
      }
    }
  }
}


```
{{< /tab >}}
{{< /tabs>}}

## What is a Schema Registry?

A schema registry is typically used in distributed data architectures where data is produced by one system and consumed
by multiple other systems. Here's an example of how a schema registry might be used in practice:

Suppose you have a streaming data pipeline that ingests data from multiple sources, processes the data in real-time, and
then outputs the processed data to multiple downstream systems for further analysis. Each source system produces data in
a different format, and each downstream system consumes data in a different format. In order to ensure that the data
flowing through the pipeline is well-formed and compatible with all of the downstream systems, you might use a schema
registry to manage the schemas for the data.

How it works:

- The source systems creates a schema (either automated or manually) and registers it in the Schema Registry from which
  they receive an ID and Version.

- The source systems produce data in a particular format, such as Avro, JSON, ProtoBuf, CSV or XML. Before producing
  data, they insert the ID and Version received in the previous step in the message metadata.

- When the data is ingested by the streaming pipeline, the data is validated against the schema definition to ensure
  that it conforms to the expected structure and data types.

- Depending on the validation result, the data will be either sent to the valid topic, where the consumers are subscribed
  to, or to the dead-letter topic, where the invalid data will reside and wait for manual inspection.

By using a schema registry to manage the schemas for the data, you can ensure that the data flowing through the pipeline
is well-formed and compatible with all the downstream systems, reducing the likelihood of data quality issues and
system failures. Additionally, by providing a central location for schema definitions, you can improve collaboration and
communication between teams working with the same data.

### Use cases

Some schema registry use cases:

- Data validation and governance: A schema registry can ensure that the data being produced and consumed by different
  systems conform to a specified schema. This helps ensure data quality and consistency across the organization, which
  is particularly important in regulated industries.

- Compatibility checking: As systems evolve over time, it's important to ensure that changes to data schemas are
  compatible with existing systems that consume the data. A schema registry can help detect incompatibilities early on
  and prevent costly failures downstream.

- Data discovery: A schema registry can be used to help data consumers discover and understand the structure of data
  available in the organization. By providing a central location for data schema definitions, a schema registry makes it
  easier for data analysts and engineers to find and understand the data they need.

- Automation: A schema registry can be integrated with other data tools and processes to automate schema-related tasks,
  such as schema validation, schema evolution, and data transformation.

- Collaboration: By providing a shared location for schema definitions, a schema registry can facilitate collaboration
  between different teams and departments working with the same data. This can help reduce duplication of effort and
  improve communication between teams.

## Schema Registry Components

The Schema Registry system consists of the following two components: **Registry** and **Validators**.

## Registry

The Registry, which itself is a database with a REST API on top, is deployed as a deployment on a Kubernetes cluster
which performs the following:

- Schema registration
- Schema updating (adding a new version of an existing schema)
- Retrieval of existing schemas (specified version or latest version)
- Deleting the whole schema or just specified versions of a schema
- Checking for schema validity (syntactically and semantically)
- Checking for schema compatibility (backward, forward, transitive)

The main component of the Schema Registry product is entirely independent of the implementation of the data-streaming
platform. It is implemented as a REST API that provides handles (via URL) for clients and communicates via HTTP
requests.

The validator component communicates with the REST API by sending the HTTP GET request that retrieves a message schema from
the Registry by using the necessary parameters. The message schemas themselves can be stored in any type of database (
Schema History), whether in tables like in standard SQL databases, such as Oracle or PostgreSQL, or NoSQL databases like
MongoDB. The component itself has an interface with the database connector that can be easily modified to
work with databases that fit the client’s needs.

## Validator

The Validator is deployed as a deployment on a Kubernetes cluster and performs the following:

- Message schema retrieval (and caching) from the Registry using message metadata
- Input message validation using the retrieved schema
- Input message transmission depending on its validation result

Before the producer starts sending messages their schema needs to be registered in the database, whether it is an
entirely new schema or a new version of an existing one. Each of the messages being sent to the input topic needs to
have its metadata enriched with the schema information, which includes the ID, version and the message format.

The role of the Validator component is to filter the messages being pushed from the input topic based on the metadata
attributes and route them to their destination. It does so with the help of the Registry component.

If the schema is registered in the database, the request sent to the Registry will return the schema specification and
the message can be successfully validated and routed to a topic for valid messages. In case of validation failure, the
message will be routed to a topic for dead letter messages.

Message brokers supported with the Validator component are:

- GCP Pub/Sub
- Azure ServiceBus
- Azure Event Hubs
- Apache Kafka
- Apache Pulsar
- NATS JetSteam

Also, the Schema registry enables the use of different protocols for producers and consumers, which ultimately enables
protocol conversion. For example, using the Schema registry protocol conversion you will be able to have a producer that
publishes messages using the Kafka protocol and a consumer that consumes messages using Pub/Sub protocol.

Providing a data schema and data the validators can determine if the given data is valid for the given schema. Data
types supported are:

- JSON
- AVRO
- Protocol Buffers
- XML
- CSV

Instead of logging metrics to standard output, the Validator component has Prometheus support for monitoring and alerting.

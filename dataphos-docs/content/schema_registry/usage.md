---
title: "Usage"
draft: false 
weight: 2
---

# The Schema Registry REST API

Even thought the Schema Registry provides REST API for registering, updating, fetching a schema, fetching all the
versions, fetching the latest, deleting a schema, etc. We will showcase here only the requests to register, update and
fetch a schema.

{{< tabs "Schema Registry REST API" >}} {{< tab "Register a schema" >}}

## Register a schema

After the Schema Registry is deployed you will have access to its API endpoint. To register a schema, you have to send a
POST request to the endpoint ```http://schema-registry-svc:8080/schemas``` in whose body you need to provide the name of the
schema, description, schema_type, specification (the schema), compatibility and validity mode.

The compatibility type determines how the Schema Registry compares the new schema with previous versions of a schema, 
for a given subject. The Dataphos Schema Registry default compatibility type is ```BACKWARD```. All the compatibility 
types are described in more detail in the sections below.

| Compatibility Type  | Changes allowed                               | Check against which schemas     | Upgrade first | Description                                                                                    |
|---------------------|-----------------------------------------------|---------------------------------|---------------|------------------------------------------------------------------------------------------------|
| BACKWARD            | Delete fields<br>Add optional fields          | Last version                    | Consumers     | Being able to understand messages from the last schema and the current schema.                 |
| BACKWARD_TRANSITIVE | Delete fields<br>Add optional fields          | All previous versions           | Consumers     | Being able to understand messages from all the previous schema versions and the current schema.|
| FORWARD             | Add fields<br>Delete optional fields          | Last version                    | Producers     | Being able to understand messages from the current schema and the next schema.                 |
| FORWARD_TRANSITIVE  | Add fields<br>Delete optional fields          | All previous versions           | Producers     | Being able to understand messages from the current schema and all the next schema versions.    |
| FULL                | Add optional fields<br>Delete optional fields | Last version                    | Any order     | Being both backward and forward compatible.                                                    |
| FULL_TRANSITIVE     | Add optional fields<br>Delete optional fields | All previous versions           | Any order     | Being both backward_transitive and forward_transitive compatible.                              |
| NONE                | All changes are accepted                      | Compatibility checking disabled | Depends       | All changes in the messages are acceptible.                                                    |


The validity type determines how strict the Schema Registry will be when registering a schema. Meaning, will it demand 
that the schema is compliant with the rules of the data format or with the schema rules.
The Dataphos Schema Registry default validity type is ```FULL```. Possible values for the validity mode are: ```FULL```, 
```NONE```, ```SYNTAX_ONLY```.

```
{
    "description": "new json schema for testing", 
    "schema_type": "json", 
    "specification":  "{\r\n  \"$id\": \"https://example.com/person.schema.json\",\r\n  \"$schema\": \"https://json-schema.org/draft/2020-12/schema\",\r\n  \"title\": \"Person\",\r\n  \"type\": \"object\",\r\n  \"properties\": {\r\n    \"firstName\": {\r\n      \"type\": \"string\",\r\n      \"description\": \"The person's first name.\"\r\n    },\r\n    \"lastName\": {\r\n      \"type\": \"string\",\r\n      \"description\": \"The person's last name.\"\r\n    },\r\n    \"age\": {\r\n      \"description\": \"Age in years which must be equal to or greater than zero.\",\r\n      \"type\": \"integer\",\r\n      \"minimum\": 0\r\n    }\r\n  }\r\n}\r\n",
    "name": "schema json",
    "compatibility_mode": "BACKWARD",
    "validity_mode": "FULL"
}
```

Using curl:

``` bash
curl -XPOST -H "Content-type: application/json" -d '{
    "description": "new json schema for testing", 
    "schema_type": "json", 
    "specification":  "{\r\n  \"$id\": \"https://example.com/person.schema.json\",\r\n  \"$schema\": \"https://json-schema.org/draft/2020-12/schema\",\r\n  \"title\": \"Person\",\r\n  \"type\": \"object\",\r\n  \"properties\": {\r\n    \"firstName\": {\r\n      \"type\": \"string\",\r\n      \"description\": \"The person's first name.\"\r\n    },\r\n    \"lastName\": {\r\n      \"type\": \"string\",\r\n      \"description\": \"The person's last name.\"\r\n    },\r\n    \"age\": {\r\n      \"description\": \"Age in years which must be equal to or greater than zero.\",\r\n      \"type\": \"integer\",\r\n      \"minimum\": 0\r\n    }\r\n  }\r\n}\r\n",
    "name": "schema json",
    "compatibility_mode": "BACKWARD",
    "validity_mode": "FULL"
}' 'http://schema-registry-svc:8080/schemas/'
```

The response to the schema registration request will be:

- STATUS 201 Created
    ```json
    {
        "identification": "32",
        "version": "1",
        "message": "schema successfully created"
    }
    ```

- STATUS 409 Conflict -> indicating that the schema already exists
    ```json
    {
        "identification": "32",
        "version": "1",
        "message": "schema already exists at id=32"
    }
    ```

- STATUS 500 Internal Server Error -> indicating a server error, which means that either the request is not correct (
  missing fields) or that the server is down.
    ```json
    {
        "message": "Internal Server Error"
    }
    ``` 

{{< /tab >}} {{< tab "Update a schema" >}}

## Update a schema

After the Schema Registry is registered you can update it by registering a new version under that schema ID. To update a
schema, you have to send a PUT request to the endpoint ```http://schema-registry-svc:8080/schemas/<schema_ID>``` in whose body
you need to provide the description (optional) of the version and the specification (the schema)

```json
{
    "description": "added field for middle name",
    "specification": "{\r\n  \"$id\": \"https://example.com/person.schema.json\",\r\n  \"$schema\": \"https://json-schema.org/draft/2020-12/schema\",\r\n  \"title\": \"Person\",\r\n  \"type\": \"object\",\r\n  \"properties\": {\r\n    \"firstName\": {\r\n      \"type\": \"string\",\r\n      \"description\": \"The person's first name.\"\r\n    },\r\n    \"lastName\": {\r\n      \"type\": \"string\",\r\n      \"description\": \"The person's last name.\"\r\n    },\r\n    \"lastName\": {\r\n      \"type\": \"string\",\r\n      \"description\": \"The person's last name.\"\r\n    },\r\n    \"age\": {\r\n      \"description\": \"Age in years which must be equal to or greater than zero.\",\r\n      \"type\": \"integer\",\r\n      \"minimum\": 0\r\n    }\r\n  }\r\n}\r\n"
}
```

Using curl:

```bash
curl -XPUT -H "Content-type: application/json" -d '{
    "description": "added field for middle name",
    "specification": "{\r\n  \"$id\": \"https://example.com/person.schema.json\",\r\n  \"$schema\": \"https://json-schema.org/draft/2020-12/schema\",\r\n  \"title\": \"Person\",\r\n  \"type\": \"object\",\r\n  \"properties\": {\r\n    \"firstName\": {\r\n      \"type\": \"string\",\r\n      \"description\": \"The person's first name.\"\r\n    },\r\n    \"lastName\": {\r\n      \"type\": \"string\",\r\n      \"description\": \"The person's last name.\"\r\n    },\r\n    \"lastName\": {\r\n      \"type\": \"string\",\r\n      \"description\": \"The person's last name.\"\r\n    },\r\n    \"age\": {\r\n      \"description\": \"Age in years which must be equal to or greater than zero.\",\r\n      \"type\": \"integer\",\r\n      \"minimum\": 0\r\n    }\r\n  }\r\n}\r\n"
}' 'http://schema-registry-svc:8080/schemas/<schema-id>'
```

The response to the schema updating request will be the same as for registering except when the updating is done
successfully it will be status 200 OK and a new version will be provided.

```json
{
    "identification": "32",
    "version": "2",
    "message": "schema successfully updated"
}
```

{{< /tab >}} {{< tab "Fetch a schema version" >}}

## Fetch a schema version

To get a schema version and its relevant details, a GET request needs to be made and the endpoint needs to be:

```
http://schema-registry-svc:8080/schemas/<schema-id>/versions/<schema-version>
```

Using curl:

```bash
curl -XGET -H "Content-type: application/json" 'http://schema-registry-svc:8080/schemas/<schema-id>/versions/<schema-version>' 
```

The response to the schema registration request will be:

- STATUS 200 OK
    ```json
    {
        "id": "32",
        "version": "1",
        "schema_id": "32",
        "specification": "ew0KICAiJHNjaGVtYSI6ICJodHRwOi8vanNvbi1zY2hlbWEub3JnL2RyYWZ0LTA3L3NjaGVtYSIsDQogICJ0eXBlIjogIm9iamVjdCIsDQogICJ0aXRsZSI6ICJUaGUgUm9vdCBTY2hlbWEiLA0KICAiZGVzY3JpcHRpb24iOiAiVGhlIHJvb3Qgc2NoZW1hIGNvbXByaXNlcyB0aGUgZW50aXJlIEpTT04gZG9jdW1lbnQuIiwNCiAgImRlZmF1bHQiOiB7fSwNCiAgImFkZGl0aW9uYWxQcm9wZXJ0aWVzIjogdHJ1ZSwNCiAgInJlcXVpcmVkIjogWw0KICAgICJwaG9uZSINCiAgXSwNCiAgInByb3BlcnRpZXMiOiB7DQogICAgInBob25lIjogew0KICAgICAgInR5cGUiOiAiaW50ZWdlciIsDQogICAgICAidGl0bGUiOiAiVGhlIFBob25lIFNjaGVtYSIsDQogICAgICAiZGVzY3JpcHRpb24iOiAiQW4gZXhwbGFuYXRpb24gYWJvdXQgdGhlIHB1cnBvc2Ugb2YgdGhpcyBpbnN0YW5jZS4iLA0KICAgICAgImRlZmF1bHQiOiAiIiwNCiAgICAgICJleGFtcGxlcyI6IFsNCiAgICAgICAgMQ0KICAgICAgXQ0KICAgIH0sDQogICAgInJvb20iOiB7DQogICAgICAidHlwZSI6ICJpbnRlZ2VyIiwNCiAgICAgICJ0aXRsZSI6ICJUaGUgUm9vbSBTY2hlbWEiLA0KICAgICAgImRlc2NyaXB0aW9uIjogIkFuIGV4cGxhbmF0aW9uIGFib3V0IHRoZSBwdXJwb3NlIG9mIHRoaXMgaW5zdGFuY2UuIiwNCiAgICAgICJkZWZhdWx0IjogIiIsDQogICAgICAiZXhhbXBsZXMiOiBbDQogICAgICAgIDEyMw0KICAgICAgXQ0KICAgIH0NCiAgfQ0KfQ==",
        "description": "new json schema for testing",
        "schema_hash": "72966008fdcec8627a0e43c5d9a247501fc4ab45687dd2929aebf8ef3eb06ccd",
        "created_at": "2023-05-09T08:38:54.5515Z",
        "autogenerated": false
    }
    ```
- STATUS 404 Not Found -> indicating that the wrong schema ID or schema version was provided
- STATUS 500 Internal Server Error -> indicating a server error, which means that either the request is not correct (
  wrong endpoint) or that the server is down.

{{< /tab >}} {{< tab "Other requests" >}}

## Other requests

|                    Description                    | Method |                                URL                                |               Headers               |                Body               |
|:-------------------------------------------------:|--------|:-----------------------------------------------------------------:|:-----------------------------------:|:---------------------------------:|
| Get all the schemas                               | GET    | http://schema-registry-svc/schemas                              | Content-Type: application/json      | This request does not have a body |
| Get all the schema versions of the specified ID   | GET    | http://schema-registry-svc/schemas/{id}/versions                | Content-Type: application/json      | This request does not have a body |
| Get the latest schema version of the specified ID | GET    | http://schema-registry-svc/schemas/{id}/versions/latest         | Content-Type: application/json      | This request does not have a body |
| Get schema specification by id and version        | GET    | http://schema-registry-svc/schemas/{id}/versions/{version}/spec | Content-Type: application/json<br>  | This request does not have a body |
| Delete the schema under the ID                    | DELETE | http://schema-registry-svc/schemas/{id}                         | Content-Type: application/json      | This request does not have a body |
| Delete the schema by id and version               | DELETE | http://schema-registry-svc/schemas/{id}/versions/{version}      | Content-Type: application/json      | This request does not have a body |


## Schema search

Aside from fetching schemas by their ID and version, they can also be fetched using search endpoint. Schemas can be 
searched on the "/schemas/search?" endpoint, following the search condition. There can be multiple criteria for the 
search, and they are in the following format: *par1=val1&par2=val2&par3=val3*.
The parameters that schema can be searched upon are as follows:
- id
- version
- type
- name
- attributes

Additionally, they can be ordered by these parameters (except for attributes) in ascending/descending order (the default
parameter to order by is ID), as well as limited to a certain number of items. The table below shows a few example of
schema search requests (none have body).

|                                        Description                                         | Method |                                           URL                                           |               Headers               |
|:------------------------------------------------------------------------------------------:|--------|:---------------------------------------------------------------------------------------:|:-----------------------------------:|
|         Get all schemas that contain *schema_name* in their name (case sensitive)          | GET    |               http://schema-registry-svc/schemas/search?name=schema_name                | Content-Type: application/json      |
|           Get all schemas that contain *schema_name* in their name and type json           | GET    |          http://schema-registry-svc/schemas/search?name=schema_name&type=json           | Content-Type: application/json      |
|                                 Get a schema with an *ID*                                  | GET    |                     http://schema-registry-svc/schemas/search?id=ID                     | Content-Type: application/json      |
|                       Get a schema with an *ID* in descending order                        | GET    |                http://schema-registry-svc/schemas/search?id=ID&sort=desc                | Content-Type: application/json      |
| Get up to 50 schemas whose name *schema_name* in ascending order in respect to their names | GET    | http://schema-registry-svc/schemas/search?id=schema_name&orderBy=name&sort=asc&limit=50 | Content-Type: application/json      |
|     Get a schema whose name contains *schema_name* and attributes *attr1* and *attr2*      | GET    |    http://schema-registry-svc/schemas/search?name=schema_name&attributes=attr1,attr2    | Content-Type: application/json      |


{{< /tab >}} {{< /tabs >}}

# Validator message format

Depending on the technology your producer uses, the way you shape the message may differ and therefore the part of the
message that contains the metadata might be called ```attributes```, ```metadata,``` etc.

Besides the data field, which contains the message data, inside the attributes (or metadata) structure it's important to
add fields ```schemaId```, ```versionId``` and ```format```
which are important information for the validator component. In case some additional attributes are provided, the validator
won't lose them, they will be delegated to the destination topic.

{{< tabs "Schema Registry - validator message format" >}} {{< tab "Pub/Sub" >}}

```json
{
  "ID": "string",
  "Data": "string",
  "Attributes": {
    "schemaId": "string",
    "versionId": "string",
    "format": "string",
    // ...
  },
  "PublishTime": "time",
}
```

| Field      | Description                                                                                                                                                                                                                                                                                                            |
|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Data       | **string** (bytes format)<br><br>The message data field. If this field is empty, the message must contain at least one attribute.<br><br>A base64-encoded string.                                                                                                                                                          |
| Attributes | **map** (key: string, value: string)<br><br>Attributes for this message. If this field is empty, the message must contain non-empty data. This can be used to filter messages on the subscription.<br><br>An object containing a list of "key": value pairs. Example: { "schemaId": "1", "versionId": "2", "format": "json" }. |
| PublishTime| **time** (time.Time format) <br><br>PublishTime is the time at which the message was published. This is populated by the server for Messages obtained from a subscription.|

{{< /tab >}}

{{< tab "ServiceBus" >}} 

```json
{
  "MessageID": "string",
  "Body": "string",
  "PartitionKey": "string", 
  "ApplicationProperties": {
    "schemaId": "string",
    "versionId": "string",
    "format": "string",
    // ...
  },
  "EnqueuedTime": "time"
}
```

| Field      | Description                                                                                                                                                                                                                                                                                                            |
|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Body       | **string** (bytes format)<br><br>The message data field. If this field is empty, the message must contain at least one application property.                                                                                                                                                         |
| ApplicationProperties | **map** (key: string, value: string)<br><br>Attributes for this message. ApplicationProperties can be used to store custom metadata for a message.<br><br>An object containing a list of "key": value pairs. Example: { "schemaId": "1", "versionId": "2", "format": "json" }. |
| PartitionKey| **string** <br><br>PartitionKey is used with a partitioned entity and enables assigning related messages to the same internal partition. This ensures that the submission sequence order is correctly recorded. The partition is chosen by a hash function in Service Bus and cannot be chosen directly.|
| EnqueuedTime| **time** (time.Time format) <br><br>EnqueuedTime is the UTC time when the message was accepted and stored by Service Bus.|

{{< /tab >}}

{{< tab "Kafka" >}} 

```json
{
  "Key": "string", 
  "Value": "string", 
  "Offset": "int64",
  "Partition": "int32",
  "Headers": {
    "schemaId": "string",
    "versionId": "string",
    "format": "string",
    // ...
  },
  "Timestamp": "time"
}
```

| Field      | Description                                                                                                                                                                                                                                                                                                            |
|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Key       | **string** (bytes format)<br><br>Key is an optional field that can be used for partition assignment.                                                                                                                                                         |
| Value       | **string** (bytes format)<br><br>Value is blob of data to write to Kafka.                                                                                                                                                       |
| Offset | **int64** <br><br> Offset is the offset that a record is written as.|
| Partition | **int32** <br><br> Partition is the partition that a record is written to.|
| Headers | **map** (key: string, value: string)<br><br>Headers are optional key/value pairs that are passed along with records.<br><br>Example: { "schemaId": "1", "versionId": "2", "format": "json" }. <br><br> These are purely for producers and consumers; Kafka does not look at this field and only writes it to disk. |
| Timestamp| **time** (time.Time format) <br><br>Timestamp is the timestamp that will be used for this record. Record batches are always written with "CreateTime", meaning that timestamps are generated by clients rather than brokers.|

{{< /tab >}}
{{< /tabs >}}


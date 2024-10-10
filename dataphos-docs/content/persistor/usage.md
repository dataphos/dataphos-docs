---
title: "Usage"
draft: false
weight: 2
---

This page outlines the general usage of the component -- primarily referring to its REST APIs utilized for indexation and resubmission.

# Persistor Core

Once the Persistor is successfully deployed, it is ready to ingest data. The ingestion is started by publishing messages to the Persistor's topic. That can be done by using the [Publisher](/publisher), or by creating your publisher for testing purposes. 

You can check the results by checking the files saved on the Google Storage or Azure Blob Storage at any point during the publishing process (assuming you have deployed the Persistor in the `Push` or `Constant Pull` model). 

If you have also deployed the Indexer component, you will find the metadata populated in the Persistor's underlying Indexer database, as well.

Both Persistor and Indexer expose their metrics on the `:2112/metrics` endpoint. There you can view information about the program runtime, memory and CPU usage, and amounts of processed data.

# Resubmitter REST API

The Persistor offers an interactive component - the **Resubmitter API**. It reconstructs the original message and re-sends it to the broker, in the same way as the original message producer would do.

To do this, Resubmitter connects to Indexer API to fetch the metadata necessary for resubmission, while also connecting to a permanent storage for retrieving payloads, and to a messaging service for publishing reconstructed messages. 
The rights to connect to the storage and the messaging service are provided by the service account used, **but there are possible issues when trying to resubmit messages to a Kafka broker using access control lists. It is possible that Kafka refuses connection to an existing topic the Resubmitter and stalls the workflow, but no errors are returned. If the resubmission is done to a topic that doesn't exist, Resubmitter will create it and successfully publish the messages.**

The Resubmitter API offers multiple methods of resubmitting messages. The core API can be found at:

```bash
http://<rsb-host>:8081/<op>/<mongo-collection>?topic=<resubmit-topic>
```

where:

- ```<op>``` is the resubmission method being used
- ```<rsb-host>``` is the DNS hostname (or IP address) of the Resubmitter API
- ```<mongo-collection>``` is the name of the mongo collection in which the metadata messages will be searched for
- ```<resubmit-topic>``` is the message broker topic where the Resubmitter will publish messages

The API answers all requests with a response containing a Status code and message, but also a summary of how many messages were a part of each process - indexing from the Mongo database, fetching from the storage, deserializing into records if necessary, and publishing to the message broker.

If Status 500 was returned, an internal error preventing the Resubmitter from processing the request happened. 

If Status 400 was returned, the Resubmitter API successfully started the resubmission pipeline, but some of the message information had been wrong and prevented any messages from being published.

If an error happened during resubmission, but only on some of the messages, a list of errors and the messages they happened on will also be returned as a part of the response, and the response will have Status 204 Partial resubmission.

{{< tabs "Resubmitter REST API" >}}
{{< tab "Resubmit by ID" >}}
## Resubmit by ID

This request resubmits messages with a unique_id within the given IDs. Unique_id consists of broker_id and message_id of the stored message in the data lake: `Unique_id = {broker_id}_{message_id}`.
To resubmit messages with some exact ID, a `POST` request to ```http://<rsb-host>:8081/resubmit/<mongo-collection>?topic=<resubmit-topic>``` must be sent with the request body containing an array of IDs of the messages to be resubmitted.

```json
{
    "ids": ["msg-topic_2523966771678879", "msg-topic_2523966771678312"]
}
```

This can also be done using curl:

```bash
curl -XPOST -H "Content-type: application/json" -d '{
    "ids": ["msg-topic_2523966771678879", "msg-topic_2523966771678312"]
}' 'http://<rsb-ip-address>:8081/resubmit/<mongo-collection>?topic=<resubmit-topic>'
```

An example of a successful response is:

```json
{
    "status": 200,
    "msg": "resubmission succesful",
    "summary": {
    	"indexed_count": 2,
    	"fetched_count": 2,
    	"deserialized_count": 2,
    	"published_count": 2
    		
    }
}
``` 

If the IDs given in the body don't have corresponding messages in the MongoDB, Status 200 OK without errors is returned, but the counters show that the messages were not successfully found in the database and were not published.

{{</ tab >}}
{{< tab "Resubmit by Time Interval" >}}

## Resubmit by Time Interval

Range request is used to resubmit all messages from a given broker_id and in the given time interval/range.

To resubmit all messages from a given topic and in the given time interval, a POST request to ```http://<rsb-host>:8081/range/<mongo-collection>?topic=<resubmit-topic>``` must be sent with the request body containing the broker_id which value is topicID from which the messages were initially ingested. 

Optionally, two other body request parameters can be defined:
- ```lb``` is the lower bound of the time interval (the one further back in time)
- ```ub``` is the upper bound of the time interval (the more recent time)

If an interval bound parameter is omitted, a default value is used instead. For the lower bound, the default value is 0001/01/01 00:00:00.000000000 UTC, while for the upper bound it is the moment the request had been made.

An example `/range` request:

```json
{
    "broker_id": "per-test-topic",
    "lb": "0001-01-01T00:00:00Z",
    "ub": "2021-09-27T14:15:05Z"
}
```

This can also be done using curl:

```bash
curl -XPOST -H "Content-type: application/json" -d '{
    "broker_id": "per-test-topic",
    "lb": "0001-01-01T00:00:00Z",
    "ub": "2021-09-27T14:15:05Z"
}' 'http://<rsb-host>:8081/range/<mongo-collection>?topic=<resubmit-topic>'
```

{{</ tab >}}
{{< tab "Resubmit by Custom Query Filter" >}}

## Resubmit by Custom Query Filter

The query request is used to resubmit all messages satisfying the custom query filter, i.e. containing exact Persistor-generated metadata values given in the request body.
To use this method, a POST request to ```http://<rsb-host>:8081/query/<mongo-collection>?topic=<resubmit-topic>``` must be sent with the request body containing the filters used.

The query filters are defined as an array of JSON objects, where each filter is represented by one object and it filters data that satisfies all of its fields. Then, all the filters are combined using the OR logical operation, meaning any data that satisfies at least one full filter is resubmitted.

JSON fields for a filter should be metadata field names, while their value should either be the exact value to be queried for or a JSON object containing more advanced information for querying.

Special keywords that can be used in JSONs:

| Operator | Description                                                         |
|:---------|:--------------------------------------------------------------------|
| $eq      | Matches values that are equal to a specified value.                 |
| $gt      | Matches values that are greater than a specified value.             |
| $gte     | Matches values that are greater than or equal to a specified value. |
| $in      | Matches any of the values specified in an array.                    |
| $lt      | Matches values that are less than a specified value.                |
| $lte     | Matches values that are less than or equal to a specified value.    |
| $ne      | Matches all values that are not equal to a specified value.         |
| $nin     | Matches none of the values specified in an array.                   |
  

Example of the request body containing filtering information:

```json 
{
    "filters" : [
        {
            "additional_metadata.a" : "x",
            "location_position" : {
                "$gte": 88, "$lt": 91
            },
            "publish_time": {
                "$gte": "2023-02-05 19:20:55.342"
            }
        },
        {
            "additional_metadata.b" : "y"
        }
    ]
}
``` 

which, by using curl, can be sent as:

```bash
curl -XPOST -H "Content-type: application/json" -d '{
    "filters" : [
        {
            "additional_metadata.a" : "x",
            "location_position" : {
                "$gte": 88, "$lt": 91
            },
            "publish_time": {
                "$gte": "2023-02-05 19:20:55.342"
            }
        },
        {
            "additional_metadata.b" : "y"
        }
    ]
}' 'http://<rsb-host>:8081/query/<mongo-collection>?topic=<resubmit-topic>'
```

Let’s say there are 80 messages with ```"additional_metadata.a" : "x"``` (meaning the message’s additional metadata has to have the field "a", and its value has to be "x"), but only 10 of them have "location_position" in [88, 91), and only 5 of those have "publish_time" after "2023-02-05 19:20:55.342" - those 5 messages would be the result for the first query filter.

In addition, if there are 100 messages with ```"additional_metadata.b" : "y"```, all of those messages will also be resubmitted. If there is an intersection between those two filter results, those messages are resubmitted only once.

It is important to note that if timestamps must be given in the format used in the example - `yyyy-MM-dd HH:mm:ss`.

Furthermore, additional metadata is best defined using single fields and values for those fields, but it can also be defined as a JSON, IE.

```json 
{
    "additional_metadata" : {
        "b": "y",
        "a": "x"
    }
}
``` 

but in that case, all fields must have correct values and their order must be the same as in the query.

If a query filter key is not a valid Persistor metadata field, an error containing the invalid keys will be returned.

{{</ tab >}}
{{</ tabs >}}

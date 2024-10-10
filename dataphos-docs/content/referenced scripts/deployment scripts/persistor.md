---
title: "Persistor Scripts"
draft: false
---

# Dataphos Persistor

## Persistor Azure
{{< details "Deployment Script" >}}

```
#!/bin/bash
if [ $# -ne 12 ]; then
        echo "please specify all required variables"
		exit 1
fi
client_id=$1
client_secret=$2
tenant_id=$3
persistor_sb_conn_string=$4
persistor_topic=$5
persistor_sub=$6
deadletter_topic=$7
storage_account=$8
container=$9
indexer_sb_conn_string=${10}
indexer_topic=${11}
indexer_sub=${12}

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
  namespace: dataphos
spec:
  selector:
    matchLabels:
      role: mongo
  serviceName: mongo-service
  template:
    metadata:
      labels:
        role: mongo
    spec:
      terminationGracePeriodSeconds: 10
      containers:
        - name: mongo
          image: mongo:4.0
          command:
            - mongod
            - "--bind_ip"
            - 0.0.0.0
            - "--smallfiles"
            - "--noprealloc"
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-persistent-volume
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongo-persistent-volume
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-service
  namespace: dataphos
  labels:
    name: mongo
spec:
  ports:
    - port: 27017
      targetPort: 27017
  clusterIP: None
  selector:
    role: mongo
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pes-config
  namespace: dataphos
data:
  READER_TYPE: "servicebus"
  SENDER_TYPE: "servicebus"
  INDEXERENABLED: "true"
  DEADLETTERENABLED: "true"
  READER_SERVICEBUS_CONNECTIONSTRING: "$persistor_sb_conn_string"
  READER_SERVICEBUS_TOPICID: $persistor_topic
  READER_SERVICEBUS_SUBID: $persistor_sub
  STORAGE_TYPE: "abs"
  STORAGE_PREFIX: "msg"
  STORAGE_MSGEXTENSION: "avro"
  STORAGE_MASK: "year/month/day/hour"
  STORAGE_CUSTOMVALUES: ""
  STORAGE_DESTINATION: $container
  STORAGE_TOPICID: $persistor_topic
  STORAGE_STORAGEACCOUNTID: $storage_account
  SENDER_TOPICID: $indexer_topic
  SENDER_DEADLETTERTOPIC: $deadletter_topic
  SENDER_SERVICEBUS_CONNECTIONSTRING: "$indexer_sb_conn_string"
  BATCHSETTINGS_BATCHSIZE: "5000"
  BATCHSETTINGS_BATCHTIMEOUT: "30s"
  BATCHSETTINGS_BATCHMEMORY: "1000000"
  AZURE_CLIENT_ID: $client_id
  AZURE_TENANT_ID: $tenant_id
  AZURE_CLIENT_SECRET: $client_secret
  MINIMUM_LOG_LEVEL: "INFO"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: persistor
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: persistor
  template:
    metadata:
      labels:
        app: persistor
    spec:
      containers:
        - name: azure-persistor
          image: syntioinc/dataphos-persistor-core:1.0.0
          ports:
            - containerPort: 2112
          envFrom:
            - configMapRef:
                name: pes-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: idx-config
  namespace: dataphos
data:
    READER_TYPE: "servicebus"
    SENDER_TYPE: "servicebus"
    DEADLETTERENABLED: "true"
    READER_SERVICEBUS_CONNECTIONSTRING: "$indexer_sb_conn_string"
    READER_SERVICEBUS_TOPICID: $indexer_topic
    READER_SERVICEBUS_SUBID: $indexer_sub
    SENDER_DEADLETTERTOPIC: $deadletter_topic
    SENDER_SERVICEBUS_CONNECTIONSTRING: "$indexer_sb_conn_string"
    MONGO_CONNECTIONSTRING: "mongodb://mongo-0.mongo-service.dataphos:27017"
    MONGO_DATABASE: "indexer_db"
    MONGO_COLLECTION: "indexer_collection"
    BATCHSETTINGS_BATCHSIZE: "5000"
    BATCHSETTINGS_BATCHTIMEOUT: "30s"
    BATCHSETTINGS_BATCHMEMORY: "1000000"
    MINIMUM_LOG_LEVEL: "INFO"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: indexer
  template:
    metadata:
      labels:
        app: indexer
    spec:
      containers:
        - name: indexer
          image: syntioinc/dataphos-persistor-indexer:1.0.0
          ports:
            - containerPort: 2112
          envFrom:
            - configMapRef:
                name: idx-config
---
apiVersion: v1
kind: Service
metadata:
  name: persistor-metrics-svc
  namespace: dataphos
  labels:
    app: persistor
spec:
  type: LoadBalancer
  ports:
    - port: 2112
  selector:
    app: persistor
---
apiVersion: v1
kind: Service
metadata:
  name: indexer-metrics-svc
  namespace: dataphos
  labels:
    app: indexer
spec:
  type: LoadBalancer
  ports:
    - port: 2112
  selector:
    app: indexer
---
apiVersion: v1
kind: Service
metadata:
  name: indexer-api-svc
  namespace: dataphos
  labels:
    app: indexer-api
spec:
  type: LoadBalancer
  ports:
    - port: 8080
  selector:
    app: indexer-api
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: idx-api-config
  namespace: dataphos
data:
  CONN: "mongodb://mongo-0.mongo-service.dataphos:27017"
  DATABASE: "indexer_db"
  MINIMUM_LOG_LEVEL: "INFO"
  SERVER_ADDRESS: ":8080"
  USE_TLS: "false"
  SERVER_TIMEOUT: "2s"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer-api-deployment
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: indexer-api
  template:
    metadata:
      labels:
        app: indexer-api
    spec:
      containers:
        - name: indexer-api
          image: syntioinc/dataphos-persistor-indexer-api:1.0.0
          envFrom:
            - configMapRef:
                name: idx-api-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rsb-config
  namespace: dataphos
data:
  INDEXER_URL: http://indexer-api-svc:8080
  AZURE_CLIENT_ID: $client_id
  AZURE_TENANT_ID: $tenant_id
  AZURE_CLIENT_SECRET: $client_secret
  SB_CONNECTION_STRING: "$persistor_sb_conn_string"
  AZURE_STORAGE_ACCOUNT_NAME: $storage_account
  MINIMUM_LOG_LEVEL: "INFO"
  STORAGE_TYPE: "abs"                      # Do not change!
  PUBLISHER_TYPE: "servicebus"                   # Do not change!
  SERVER_ADDRESS: ":8081"
  USE_TLS: "false"
  SERVER_TIMEOUT: "2s"
  RSB_META_CAPACITY: "20000"
  RSB_FETCH_CAPACITY: "200"
  RSB_WORKER_NUM: "3"
  RSB_ENABLE_MESSAGE_ORDERING: "false"
---
apiVersion: v1
kind: Service
metadata:
  name: resubmitter-svc
  namespace: dataphos
  labels:
    app: resubmitter
spec:
  type: LoadBalancer
  ports:
    - port: 8081
  selector:
    app: resubmitter
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resubmitter-deployment
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: resubmitter
  template:
    metadata:
      labels:
        app: resubmitter
    spec:
      containers:
        - name: resubmitter
          image: syntioinc/dataphos-persistor-resubmitter:1.0.0
          envFrom:
            - configMapRef:
                name: rsb-config
---
EOF

```
{{< /details >}}


## Persistor GCP
{{< details "Deployment Script" >}}

```
#!/bin/bash
if [ $# -ne 8 ]; then
        echo "please specify all required variables"
		exit 1
fi
project_id=$1
persistor_topic=$2
persistor_sub=$3
bucket=$4
deadletter_topic=$5
indexer_topic=$6
indexer_sub=$7
path_to_key_file=$8

kubectl create secret generic per-gcp-access -n dataphos --from-file=key.json=$path_to_key_file
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
  namespace: dataphos
spec:
  selector:
    matchLabels:
      role: mongo
  serviceName: mongo-service
  template:
    metadata:
      labels:
        role: mongo
    spec:
      terminationGracePeriodSeconds: 10
      containers:
        - name: mongo
          image: mongo:4.0
          command:
            - mongod
            - "--bind_ip"
            - 0.0.0.0
            - "--smallfiles"
            - "--noprealloc"
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-persistent-volume
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongo-persistent-volume
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-service
  namespace: dataphos
  labels:
    name: mongo
spec:
  ports:
    - port: 27017
      targetPort: 27017
  clusterIP: None
  selector:
    role: mongo
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pes-config
  namespace: dataphos
data:
  READER_TYPE: "pubsub"
  SENDER_TYPE: "pubsub"
  INDEXERENABLED: "true"
  DEADLETTERENABLED: "true"
  READER_PUBSUB_PROJECTID: $project_id
  READER_PUBSUB_SUBID: $persistor_sub
  STORAGE_TYPE: "gcs"
  STORAGE_PREFIX: "msg"
  STORAGE_MSGEXTENSION: "avro"
  STORAGE_MASK: "year/month/day/hour"
  STORAGE_CUSTOMVALUES: ""
  STORAGE_DESTINATION: $bucket
  STORAGE_TOPICID: $persistor_topic
  SENDER_TOPICID: $indexer_topic
  SENDER_DEADLETTERTOPIC: $deadletter_topic
  SENDER_PUBSUB_PROJECTID: $project_id
  BATCHSETTINGS_BATCHSIZE: "5000"
  BATCHSETTINGS_BATCHTIMEOUT: "30s"
  BATCHSETTINGS_BATCHMEMORY: "1000000"
  MINIMUM_LOG_LEVEL: "INFO"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: persistor
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: persistor
  template:
    metadata:
      labels:
        app: persistor
    spec:
      volumes:
        - name: google-cloud-key
          secret:
            secretName: per-gcp-access
      containers:
        - name: gcp-persistor
          image: syntioinc/dataphos-persistor-core:1.0.0
          volumeMounts:
            - mountPath: /var/secrets/google
              name: google-cloud-key
          ports:
            - containerPort: 2112
          envFrom:
            - configMapRef:
                name: pes-config
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/secrets/google/key.json
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: idx-config
  namespace: dataphos
data:
  READER_TYPE: "pubsub"
  SENDER_TYPE: "pubsub"
  DEADLETTERENABLED: "true"
  READER_PUBSUB_PROJECTID: $project_id
  READER_PUBSUB_SUBID: $indexer_sub
  MONGO_CONNECTIONSTRING: "mongodb://mongo-0.mongo-service.dataphos:27017"
  MONGO_DATABASE: "indexer_db"
  MONGO_COLLECTION: "indexer_collection"
  SENDER_DEADLETTERTOPIC: $deadletter_topic
  SENDER_PUBSUB_PROJECTID: $project_id
  BATCHSETTINGS_BATCHSIZE: "5000"
  BATCHSETTINGS_BATCHTIMEOUT: "30s"
  BATCHSETTINGS_BATCHMEMORY: "1000000"
  MINIMUM_LOG_LEVEL: "INFO"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: indexer
  template:
    metadata:
      labels:
        app: indexer
    spec:
      volumes:
        - name: google-cloud-key
          secret:
            secretName: per-gcp-access
      containers:
        - name: indexer
          image: syntioinc/dataphos-persistor-indexer:1.0.0
          volumeMounts:
            - mountPath: /var/secrets/google
              name: google-cloud-key
          ports:
            - containerPort: 2112
          envFrom:
            - configMapRef:
                name: idx-config
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/secrets/google/key.json
---
apiVersion: v1
kind: Service
metadata:
  name: persistor-metrics-svc
  namespace: dataphos
  labels:
    app: persistor
spec:
  type: LoadBalancer
  ports:
    - port: 2112
  selector:
    app: persistor
---
apiVersion: v1
kind: Service
metadata:
  name: indexer-metrics-svc
  namespace: dataphos
  labels:
    app: indexer
spec:
  type: LoadBalancer
  ports:
    - port: 2112
  selector:
    app: indexer
---
apiVersion: v1
kind: Service
metadata:
  name: indexer-api-svc
  namespace: dataphos
  labels:
    app: indexer-api
spec:
  type: LoadBalancer
  ports:
    - port: 8080
  selector:
    app: indexer-api
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: idx-api-config
  namespace: dataphos
data:
  CONN: "mongodb://mongo-0.mongo-service.dataphos:27017"
  DATABASE: "indexer_db"
  MINIMUM_LOG_LEVEL: "WARN"
  SERVER_ADDRESS: ":8080"
  USE_TLS: "false"
  SERVER_TIMEOUT: "10s"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer-api-deployment
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: indexer-api
  template:
    metadata:
      labels:
        app: indexer-api
    spec:
      containers:
        - name: indexer-api
          image: syntioinc/dataphos-persistor-indexer-api:1.0.0
          envFrom:
            - configMapRef:
                name: idx-api-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rsb-config
  namespace: dataphos
data:
  PUBSUB_PROJECT_ID: $project_id
  INDEXER_URL: "http://indexer-api-svc:8080"
  MINIMUM_LOG_LEVEL: "WARN"
  SERVER_ADDRESS: ":8081"
  USE_TLS: "false"
  SERVER_TIMEOUT: "10s"
  RSB_META_CAPACITY: "20000"
  RSB_FETCH_CAPACITY: "200"
  RSB_WORKER_NUM: "3"
  RSB_ENABLE_MESSAGE_ORDERING: "false"
  STORAGE_TYPE: "gcs"                         # Do not change!
  PUBLISHER_TYPE: "pubsub"                   # Do not change!
  PUBLISH_TIMEOUT: "15s"
  PUBLISH_COUNT_THRESHOLD: "50"
  PUBLISH_DELAY_THRESHOLD: "50ms"
  NUM_PUBLISH_GOROUTINES: "10"
  MAX_PUBLISH_OUTSTANDING_MESSAGES: "800"
  MAX_PUBLISH_OUTSTANDING_BYTES: "1048576000"
  PUBLISH_ENABLE_MESSAGE_ORDERING: "false"
---
apiVersion: v1
kind: Service
metadata:
  name: resubmitter-svc
  namespace: dataphos
  labels:
    app: resubmitter
spec:
  type: LoadBalancer
  ports:
    - port: 8081
  selector:
    app: resubmitter
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resubmitter-deployment
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: resubmitter
  template:
    metadata:
      labels:
        app: resubmitter
    spec:
      volumes:
        - name: google-cloud-key
          secret:
            secretName: per-gcp-access
      containers:
        - name: resubmitter
          image: syntioinc/dataphos-persistor-resubmitter:1.0.0
          volumeMounts:
            - mountPath: /var/secrets/google
              name: google-cloud-key
          envFrom:
            - configMapRef:
                name: rsb-config
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/secrets/google/key.json
---
EOF

```
{{< /details >}}

## Persistor Kafka to Azure Blog Storage
{{< details "Deployment Script" >}}
```
#!/bin/bash
if [ $# -ne 12 ]; then
        echo "please specify all required variables"
		exit 1
fi
client_id=$1
client_secret=$2
tenant_id=$3
persistor_kafka_address=$4
persistor_topic=$5
kafka_consumer_persistor_group_id=$6
storage_account=$7
container=$8
deadletter_topic=$9
indexer_kafka_address=${10}
indexer_topic=${11}
kafka_consumer_indexer_group_id=${12}

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
  namespace: dataphos
spec:
  selector:
    matchLabels:
      role: mongo
  serviceName: mongo-service
  template:
    metadata:
      labels:
        role: mongo
    spec:
      terminationGracePeriodSeconds: 10
      containers:
        - name: mongo
          image: mongo:4.0
          command:
            - mongod
            - "--bind_ip"
            - 0.0.0.0
            - "--smallfiles"
            - "--noprealloc"
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-persistent-volume
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongo-persistent-volume
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-service
  namespace: dataphos
  labels:
    name: mongo
spec:
  ports:
    - port: 27017
      targetPort: 27017
  clusterIP: None
  selector:
    role: mongo
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pes-config
  namespace: dataphos
data:
  READER_TYPE: "kafka"
  SENDER_TYPE: "kafka"
  INDEXERENABLED: "true"
  DEADLETTERENABLED: "true"
  READER_KAFKA_TOPICID: $persistor_topic
  READER_KAFKA_ADDRESS: $persistor_kafka_address
  READER_KAFKA_GROUPID: $kafka_consumer_persistor_group_id
  STORAGE_TYPE: "abs"
  STORAGE_PREFIX: "msg"
  STORAGE_MSGEXTENSION: "avro"
  STORAGE_MASK: "year/month/day/hour"
  STORAGE_CUSTOMVALUES: ""
  STORAGE_DESTINATION: $container
  STORAGE_TOPICID: $persistor_topic
  STORAGE_STORAGEACCOUNTID: $storage_account
  SENDER_TOPICID: $indexer_topic
  SENDER_DEADLETTERTOPIC: $deadletter_topic
  SENDER_KAFKA_ADDRESS: $indexer_kafka_address
  BATCHSETTINGS_BATCHSIZE: "5000"
  BATCHSETTINGS_BATCHTIMEOUT: "30s"
  BATCHSETTINGS_BATCHMEMORY: "1000000"
  AZURE_CLIENT_ID: $client_id
  AZURE_TENANT_ID: $tenant_id
  AZURE_CLIENT_SECRET: $client_secret
  MINIMUM_LOG_LEVEL: "INFO"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: persistor
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: persistor
  template:
    metadata:
      labels:
        app: persistor
    spec:
      containers:
        - name: azure-persistor
          image: syntioinc/dataphos-persistor-core:1.0.0
          ports:
            - containerPort: 2112
          envFrom:
            - configMapRef:
                name: pes-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: idx-config
  namespace: dataphos
data:
    READER_TYPE: "kafka"
    SENDER_TYPE: "kafka"
    DEADLETTERENABLED: "true"
    READER_KAFKA_TOPICID: $indexer_topic
    READER_KAFKA_ADDRESS: $indexer_kafka_address
    READER_KAFKA_GROUPID: $kafka_consumer_indexer_group_id
    SENDER_DEADLETTERTOPIC: $deadletter_topic
    MONGO_CONNECTIONSTRING: "mongodb://mongo-0.mongo-service.dataphos:27017"
    MONGO_DATABASE: "indexer_db"
    MONGO_COLLECTION: "indexer_collection"
    SENDER_KAFKA_ADDRESS: $indexer_kafka_address
    BATCHSETTINGS_BATCHSIZE: "5000"
    BATCHSETTINGS_BATCHTIMEOUT: "30s"
    BATCHSETTINGS_BATCHMEMORY: "1000000"
    MINIMUM_LOG_LEVEL: "INFO"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: indexer
  template:
    metadata:
      labels:
        app: indexer
    spec:
      containers:
        - name: indexer
          image: syntioinc/dataphos-persistor-indexer:1.0.0
          ports:
            - containerPort: 2112
          envFrom:
            - configMapRef:
                name: idx-config
---
apiVersion: v1
kind: Service
metadata:
  name: persistor-metrics-svc
  namespace: dataphos
  labels:
    app: persistor
spec:
  type: LoadBalancer
  ports:
    - port: 2112
  selector:
    app: persistor
---
apiVersion: v1
kind: Service
metadata:
  name: indexer-metrics-svc
  namespace: dataphos
  labels:
    app: indexer
spec:
  type: LoadBalancer
  ports:
    - port: 2112
  selector:
    app: indexer
---
apiVersion: v1
kind: Service
metadata:
  name: indexer-api-svc
  namespace: dataphos
  labels:
    app: indexer-api
spec:
  type: LoadBalancer
  ports:
    - port: 8080
  selector:
    app: indexer-api
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: idx-api-config
  namespace: dataphos
data:
  CONN: "mongodb://mongo-0.mongo-service.dataphos:27017"
  DATABASE: "indexer_db"
  MINIMUM_LOG_LEVEL: "INFO"
  SERVER_ADDRESS: ":8080"
  USE_TLS: "false"
  SERVER_TIMEOUT: "2s"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer-api-deployment
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: indexer-api
  template:
    metadata:
      labels:
        app: indexer-api
    spec:
      containers:
        - name: indexer-api
          image: syntioinc/dataphos-persistor-indexer-api:1.0.0
          envFrom:
            - configMapRef:
                name: idx-api-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rsb-config
  namespace: dataphos
data:
  MINIMUM_LOG_LEVEL: "INFO"
  INDEXER_URL: http://indexer-api-svc:8080
  STORAGE_TYPE: "abs"                      # Do not change!
  PUBLISHER_TYPE: "kafka"                   # Do not change!
  SERVER_ADDRESS: ":8081"
  USE_TLS: "false"
  SERVER_TIMEOUT: "10s"
  RSB_META_CAPACITY: "20000"
  RSB_FETCH_CAPACITY: "200"
  RSB_WORKER_NUM: "3"
  RSB_ENABLE_MESSAGE_ORDERING: "false"
  AZURE_CLIENT_ID: $client_id
  AZURE_TENANT_ID: $tenant_id
  AZURE_CLIENT_SECRET: $client_secret
  AZURE_STORAGE_ACCOUNT_NAME: $storage_account
  KAFKA_BROKERS: $persistor_kafka_address
  KAFKA_USE_TLS: "false"
  KAFKA_USE_SASL: "false"
  SASL_USERNAME: "default"
  SASL_PASSWORD: "default"
  KAFKA_SKIP_VERIFY: "false"
  KAFKA_DISABLE_COMPRESSION: "false"
  KAFKA_BATCH_SIZE: "50"
  KAFKA_BATCH_BYTES: "52428800"
  KAFKA_BATCH_TIMEOUT: "10ms"
  ENABLE_KERBEROS: "false"
  KRB_CONFIG_PATH: "/path/to/config/file"
  KRB_REALM: "REALM.com"
  KRB_SERVICE_NAME: "kerberos-service"
  KRB_KEY_TAB: "/path/to/file.keytab"
  KRB_USERNAME: "user"
---
apiVersion: v1
kind: Service
metadata:
  name: resubmitter-svc
  namespace: dataphos
  labels:
    app: resubmitter
spec:
  type: LoadBalancer
  ports:
    - port: 8081
  selector:
    app: resubmitter
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resubmitter-deployment
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: resubmitter
  template:
    metadata:
      labels:
        app: resubmitter
    spec:
      containers:
        - name: resubmitter
          image: syntioinc/dataphos-persistor-resubmitter:1.0.0
          envFrom:
            - configMapRef:
                name: rsb-config
---
EOF

```
{{< /details >}}

## Persistor Kafka to GCS

{{< details "Deployment Script" >}}

```
#!/bin/bash
if [ $# -ne 10 ]; then
        echo "please specify all required variables"
		exit 1
fi
project_id=$1
persistor_kafka_address=$2
persistor_topic=$3
kafka_consumer_persistor_group_id=$4
bucket=$5
deadletter_topic=$6
indexer_kafka_address=$7
indexer_topic=$8
kafka_consumer_indexer_group_id=$9
path_to_key_file=${10}

kubectl create secret generic per-gcp-access -n dataphos --from-file=key.json=$path_to_key_file
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
  namespace: dataphos
spec:
  selector:
    matchLabels:
      role: mongo
  serviceName: mongo-service
  template:
    metadata:
      labels:
        role: mongo
    spec:
      terminationGracePeriodSeconds: 10
      containers:
        - name: mongo
          image: mongo:4.0
          command:
            - mongod
            - "--bind_ip"
            - 0.0.0.0
            - "--smallfiles"
            - "--noprealloc"
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-persistent-volume
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongo-persistent-volume
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-service
  namespace: dataphos
  labels:
    name: mongo
spec:
  ports:
    - port: 27017
      targetPort: 27017
  clusterIP: None
  selector:
    role: mongo
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pes-config
  namespace: dataphos
data:
  READER_TYPE: "kafka"
  SENDER_TYPE: "kafka"
  INDEXERENABLED: "true"
  DEADLETTERENABLED: "true"
  READER_KAFKA_TOPICID: $persistor_topic
  READER_KAFKA_ADDRESS: $persistor_kafka_address
  READER_KAFKA_GROUPID: $kafka_consumer_persistor_group_id
  STORAGE_TYPE: "gcs"
  STORAGE_PREFIX: "msg"
  STORAGE_MSGEXTENSION: "avro"
  STORAGE_MASK: "year/month/day/hour"
  STORAGE_CUSTOMVALUES: ""
  STORAGE_DESTINATION: $bucket
  STORAGE_TOPICID: $persistor_topic
  SENDER_TOPICID: $indexer_topic
  SENDER_DEADLETTERTOPIC: $deadletter_topic
  SENDER_KAFKA_ADDRESS: $indexer_kafka_address
  BATCHSETTINGS_BATCHSIZE: "5000"
  BATCHSETTINGS_BATCHTIMEOUT: "30s"
  BATCHSETTINGS_BATCHMEMORY: "1000000"
  MINIMUM_LOG_LEVEL: "INFO"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: persistor
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: persistor
  template:
    metadata:
      labels:
        app: persistor
    spec:
      volumes:
        - name: google-cloud-key
          secret:
            secretName: per-gcp-access
      containers:
        - name: gcp-persistor
          image: syntioinc/dataphos-persistor-core:1.0.0
          volumeMounts:
            - mountPath: /var/secrets/google
              name: google-cloud-key
          ports:
            - containerPort: 2112
          envFrom:
            - configMapRef:
                name: pes-config
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/secrets/google/key.json
      imagePullSecrets:
        - name: nexuscred
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: idx-config
  namespace: dataphos
data:
    READER_TYPE: "kafka"
    SENDER_TYPE: "kafka"
    DEADLETTERENABLED: "true"
    READER_KAFKA_TOPICID: $indexer_topic
    READER_KAFKA_ADDRESS: $indexer_kafka_address
    READER_KAFKA_GROUPID: $kafka_consumer_indexer_group_id
    SENDER_DEADLETTERTOPIC: $deadletter_topic
    MONGO_CONNECTIONSTRING: "mongodb://mongo-0.mongo-service.dataphos:27017"
    MONGO_DATABASE: "indexer_db"
    MONGO_COLLECTION: "indexer_collection"
    SENDER_KAFKA_ADDRESS: $indexer_kafka_address
    BATCHSETTINGS_BATCHSIZE: "5000"
    BATCHSETTINGS_BATCHTIMEOUT: "30s"
    BATCHSETTINGS_BATCHMEMORY: "1000000"
    MINIMUM_LOG_LEVEL: "INFO"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: indexer
  template:
    metadata:
      labels:
        app: indexer
    spec:
      volumes:
        - name: google-cloud-key
          secret:
            secretName: per-gcp-access
      containers:
        - name: indexer
          image: syntioinc/dataphos-persistor-indexer:1.0.0
          volumeMounts:
            - mountPath: /var/secrets/google
              name: google-cloud-key
          ports:
            - containerPort: 2112
          envFrom:
            - configMapRef:
                name: idx-config
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/secrets/google/key.json
---
apiVersion: v1
kind: Service
metadata:
  name: persistor-metrics-svc
  namespace: dataphos
  labels:
    app: persistor
spec:
  type: LoadBalancer
  ports:
    - port: 2112
  selector:
    app: persistor
---
apiVersion: v1
kind: Service
metadata:
  name: indexer-metrics-svc
  namespace: dataphos
  labels:
    app: indexer
spec:
  type: LoadBalancer
  ports:
    - port: 2112
  selector:
    app: indexer
---
apiVersion: v1
kind: Service
metadata:
  name: indexer-api-svc
  namespace: dataphos
  labels:
    app: indexer-api
spec:
  type: LoadBalancer
  ports:
    - port: 8080
  selector:
    app: indexer-api
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: idx-api-config
  namespace: dataphos
data:
  CONN: "mongodb://mongo-0.mongo-service.dataphos:27017"
  DATABASE: "indexer_db"
  MINIMUM_LOG_LEVEL: "INFO"
  SERVER_ADDRESS: ":8080"
  USE_TLS: "false"
  SERVER_TIMEOUT: "10s"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer-api-deployment
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: indexer-api
  template:
    metadata:
      labels:
        app: indexer-api
    spec:
      containers:
        - name: indexer-api
          image: syntioinc/dataphos-persistor-indexer-api:1.0.0
          envFrom:
            - configMapRef:
                name: idx-api-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rsb-config
  namespace: dataphos
data:
  PUBSUB_PROJECT_ID: $project_id
  INDEXER_URL: "http://indexer-api-svc:8080"
  MINIMUM_LOG_LEVEL: "INFO"
  SERVER_ADDRESS: ":8081"
  USE_TLS: "false"
  SERVER_TIMEOUT: "10s"
  RSB_META_CAPACITY: "20000"
  RSB_FETCH_CAPACITY: "200"
  RSB_WORKER_NUM: "3"
  RSB_ENABLE_MESSAGE_ORDERING: "false"
  STORAGE_TYPE: "gcs"                         # Do not change!
  PUBLISHER_TYPE: "kafka"                   # Do not change!
  KAFKA_BROKERS: $persistor_kafka_address
  KAFKA_USE_TLS: "false"
  KAFKA_USE_SASL: "false"
  SASL_USERNAME: "default"
  SASL_PASSWORD: "default"
  KAFKA_SKIP_VERIFY: "false"
  KAFKA_DISABLE_COMPRESSION: "false"
  KAFKA_BATCH_SIZE: "50"
  KAFKA_BATCH_BYTES: "52428800"
  KAFKA_BATCH_TIMEOUT: "10ms"
  ENABLE_KERBEROS: "false"
  KRB_CONFIG_PATH: "/path/to/config/file"
  KRB_REALM: "REALM.com"
  KRB_SERVICE_NAME: "kerberos-service"
  KRB_KEY_TAB: "/path/to/file.keytab"
  KRB_USERNAME: "user"
---
apiVersion: v1
kind: Service
metadata:
  name: resubmitter-svc
  namespace: dataphos
  labels:
    app: resubmitter
spec:
  type: LoadBalancer
  ports:
    - port: 8081
  selector:
    app: resubmitter
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resubmitter-deployment
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: resubmitter
  template:
    metadata:
      labels:
        app: resubmitter
    spec:
      volumes:
        - name: google-cloud-key
          secret:
            secretName: per-gcp-access
      containers:
        - name: resubmitter
          image: syntioinc/dataphos-persistor-resubmitter:1.0.0
          volumeMounts:
            - mountPath: /var/secrets/google
              name: google-cloud-key
          envFrom:
            - configMapRef:
                name: rsb-config
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/secrets/google/key.json
---
EOF

```
{{< /details >}}
## Delete deployment

{{< details "Deletion Script" >}}

```
#!/bin/bash
kubectl delete secret per-gcp-access -n dataphos
kubectl delete -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
  namespace: dataphos
spec:
  selector:
    matchLabels:
      role: mongo
  serviceName: mongo-service
  template:
    metadata:
      labels:
        role: mongo
    spec:
      terminationGracePeriodSeconds: 10
      containers:
        - name: mongo
          image: mongo:4.0
          command:
            - mongod
            - "--bind_ip"
            - 0.0.0.0
            - "--smallfiles"
            - "--noprealloc"
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-persistent-volume
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongo-persistent-volume
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-service
  namespace: dataphos
  labels:
    name: mongo
spec:
  ports:
    - port: 27017
      targetPort: 27017
  clusterIP: None
  selector:
    role: mongo
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pes-config
  namespace: dataphos
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: persistor
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: persistor
  template:
    metadata:
      labels:
        app: persistor
    spec:
      containers:
        - name: azure-persistor
          image: syntioinc/dataphos-persistor-core:1.0.0
          envFrom:
            - configMapRef:
                name: pes-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: idx-config
  namespace: dataphos
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: indexer
  template:
    metadata:
      labels:
        app: indexer
    spec:
      containers:
        - name: indexer
          image: syntioinc/dataphos-persistor-indexer:1.0.0
          envFrom:
            - configMapRef:
                name: idx-config
---
apiVersion: v1
kind: Service
metadata:
  name: indexer-metrics-svc
  namespace: dataphos
  labels:
    app: indexer
spec:
  type: LoadBalancer
  ports:
    - port: 2112
  selector:
    app: indexer
---
apiVersion: v1
kind: Service
metadata:
  name: persistor-metrics-svc
  namespace: dataphos
  labels:
    app: persistor
spec:
  type: LoadBalancer
  ports:
    - port: 2112
  selector:
    app: persistor
---
apiVersion: v1
kind: Service
metadata:
  name: indexer-api-svc
  namespace: dataphos
  labels:
    app: indexer-api
spec:
  type: LoadBalancer
  ports:
    - port: 8080
  selector:
    app: indexer-api
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: idx-api-config
  namespace: dataphos
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer-api-deployment
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: indexer-api
  template:
    metadata:
      labels:
        app: indexer-api
    spec:
      containers:
        - name: indexer-api
          image: syntioinc/dataphos-persistor-indexer-api:1.0.0
          envFrom:
            - configMapRef:
                name: idx-api-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rsb-config
  namespace: dataphos
---
apiVersion: v1
kind: Service
metadata:
  name: resubmitter-svc
  namespace: dataphos
  labels:
    app: resubmitter
spec:
  type: LoadBalancer
  ports:
    - port: 8081
  selector:
    app: resubmitter
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resubmitter-deployment
  namespace: dataphos
spec:
  replicas: 1
  selector:
    matchLabels:
      app: resubmitter
  template:
    metadata:
      labels:
        app: resubmitter
    spec:
      containers:
        - name: resubmitter
          image: syntioinc/dataphos-persistor-resubmitter:1.0.0
          envFrom:
            - configMapRef:
                name: rsb-config
---
EOF
```
{{< /details >}}

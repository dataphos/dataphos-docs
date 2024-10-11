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

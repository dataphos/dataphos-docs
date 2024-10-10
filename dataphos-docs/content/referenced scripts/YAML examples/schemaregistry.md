---
title: "Schema Registry Examples"
draft: false
weight: 3
---

# Dataphos Schema Registry

## Schema Registry API
{{< details "YAML example" >}}

```
apiVersion: v1
kind: Secret
metadata:
  name: schema-registry-secret
  namespace: dataphos
type: Opaque
stringData:
  POSTGRES_PASSWORD: $postgres_password # insert password here
  PGDATA: /data/pgdata
  SR_HOST: schema-history-svc
  SR_TABLE_PREFIX: syntio_schema.
  SR_DBNAME: postgres
  SR_USER: postgres
  SERVER_PORT: "8080"

---
# Schema history service
apiVersion: "v1"
kind: "Service"
metadata:
  name: "schema-history-svc"
  namespace: dataphos
spec:
  ports:
    - protocol: "TCP"
      port: 5432
      targetPort: 5432
  selector:
    app: "schema-history"
  type: "ClusterIP"
---
# Schema history (PostgreSQL database that stores the schemas)
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: "schema-history"
  namespace: dataphos
  annotations:
    "syntio.net/logme": "true"
spec:
  serviceName: "schema-history-svc"
  selector:
    matchLabels:
      app: "schema-history"
  replicas: 1
  template:
    metadata:
      labels:
        app: "schema-history"
    spec:
      containers:
        - name: "schema-history"
          image: postgres:latest
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: POSTGRES_PASSWORD
            - name: PGDATA
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: PGDATA
          volumeMounts:
            - mountPath: /data
              name: "schema-history-disk"
  # Volume Claim
  volumeClaimTemplates:
    - metadata:
        name: "schema-history-disk"
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 25Gi
---
# Registry service
apiVersion: "v1"
kind: "Service"
metadata:
  name: "schema-registry-svc"
  namespace: dataphos
spec:
  ports:
    - name: http
      port: 8080
      targetPort: http
    - name: compatiblity
      port: 8088
      targetPort: compatiblity
    - name: validity
      port: 8089
      targetPort: validity
  selector:
    app: "schema-registry"
  type: "LoadBalancer"
  loadBalancerIP: ""
---
# Registry deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: schema-registry
  namespace: dataphos
  annotations:
    "syntio.net/logme": "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: schema-registry
  template:
    metadata:
      labels:
        app: schema-registry
    spec:
      volumes:
        - name: google-cloud-key
          secret:
            secretName: service-account-credentials
      initContainers:
        - name: check-schema-history-health
          image: busybox
          command: [
              "/bin/sh",
              "-c",
              "until nc -zv schema-history-svc 5432 -w1; do echo 'waiting for db'; sleep 1; done"
          ]
        - name: initdb
          image: syntioinc/dataphos-schema-registry-initdb:1.0.0
          env:
            - name: SR_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: POSTGRES_PASSWORD
            - name: SR_HOST
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: SR_HOST
            - name: SR_TABLE_PREFIX
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: SR_TABLE_PREFIX
            - name: SR_DBNAME
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: SR_DBNAME
            - name: SR_USER
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: SR_USER
          securityContext:
            privileged: false
      containers:
        - name: gke-sr
          image: syntioinc/dataphos-schema-registry-api:1.0.0
          env:
            - name: SR_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: POSTGRES_PASSWORD
            - name: SR_HOST
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: SR_HOST
            - name: SR_TABLE_PREFIX
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: SR_TABLE_PREFIX
            - name: SR_DBNAME
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: SR_DBNAME
            - name: SR_USER
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: SR_USER
            - name: SERVER_PORT
              valueFrom:
                secretKeyRef:
                  name: schema-registry-secret
                  key: SERVER_PORT
            - name: COMPATIBILITY_CHECKER_URL
              value: "http://localhost:8088"
            - name: VALIDITY_CHECKER_URL
              value: "http://localhost:8089"
          resources:
            limits:
              cpu: "400m"
              memory: "500Mi"
            requests:
              cpu: "400m"
              memory: "500Mi"
          ports:
            - name: http
              containerPort: 8080
        - name: compatibility-checker
          image: syntioinc/dataphos-schema-registry-compatibility:1.0.0
          ports:
            - name: compatibility
              containerPort: 8088
        - name: validity-checker
          image: syntioinc/dataphos-schema-registry-validity:1.0.0
          ports:
            - name: validity
              containerPort: 8089
---
```
{{< /details >}}

## Schema Registry Validator General
{{< details "YAML example" >}}

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: dataphos
data:
# Uncomment the type you want to use and fill the values for it

#  CONSUMER_TYPE: "kafka"
#  CONSUMER_KAFKA_ADDRESS:
#  CONSUMER_KAFKA_TOPIC:
#  CONSUMER_KAFKA_GROUP_ID:

#  CONSUMER_TYPE: "pubsub"
#  CONSUMER_PUBSUB_PROJECT_ID:
#  CONSUMER_PUBSUB_SUBSCRIPTION_ID:

#  CONSUMER_TYPE: "servicebus"
#  CONSUMER_SERVICEBUS_CONNECTION_STRING:
#  CONSUMER_SERVICEBUS_TOPIC:
#  CONSUMER_SERVICEBUS_SUBSCRIPTION:


#  PRODUCER_TYPE: "kafka"
#  PRODUCER_KAFKA_ADDRESS:

#  PRODUCER_TYPE: "pubsub"
#  PRODUCER_PUBSUB_PROJECT_ID:

#  PRODUCER_TYPE: "servicebus"
#  PRODUCER_SERVICEBUS_CONNECTION_STRING:

  TOPICS_VALID:
  TOPICS_DEAD_LETTER:

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_JSON:
  VALIDATORS_ENABLE_AVRO:
  VALIDATORS_ENABLE_PROTOBUF:
  VALIDATORS_ENABLE_CSV:
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_ENABLE_XML:
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: dataphos
spec:
  ports:
    - name: metrics
      port: 2112
      targetPort: 2112
  selector:
    app: "centralconsumer"
  type: "LoadBalancer"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: centralconsumer
  namespace: dataphos
  annotations:
    "syntio.net/logme": "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: centralconsumer
  template:
    metadata:
      labels:
        app: centralconsumer
    spec:
      volumes:
        - name: google-cloud-key
          secret:
            secretName: service-account-credentials
      containers:
        - name: centralconsumer
          image: syntioinc/dataphos-schema-registry-validator:1.0.0
          resources:
            limits:
              cpu: "125m"
              memory: "80Mi"
            requests:
              cpu: "125m"
              memory: "40Mi"
          volumeMounts:
            - mountPath: /var/secrets/google
              name: google-cloud-key
          envFrom:
            - configMapRef:
                name: centralconsumer-config
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/secrets/google/key.json
          ports:
            - name: metrics
              containerPort: 2112
      imagePullSecrets:
        - name: nexuscred

---
```
{{< /details >}}

## Schema Registry Validator Kafka
{{< details "YAML example" >}}

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: dataphos
data:
  CONSUMER_TYPE: "kafka"
  CONSUMER_KAFKA_ADDRESS: $consumer_address # insert consumer bootstrap server here
  CONSUMER_KAFKA_TOPIC: $consumer_topic # insert consumer topic
  CONSUMER_KAFKA_GROUP_ID: $consumer_group_id # insert consumer group ID

  PRODUCER_TYPE: "kafka"
  PRODUCER_KAFKA_ADDRESS: $producer_address # insert producer bootstrap server here

  TOPICS_VALID: $producer_valid_topic_ID # insert producer valid topic
  TOPICS_DEAD_LETTER: $producer_deadletter_topic_ID # insert producer dead-letter topic

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_JSON: "true"
  VALIDATORS_ENABLE_AVRO: "false"
  VALIDATORS_ENABLE_PROTOBUF: "false"
  VALIDATORS_ENABLE_CSV: "false"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_ENABLE_XML: "false"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: dataphos
spec:
  ports:
    - name: metrics
      port: 2112
      targetPort: 2112
  selector:
    app: "centralconsumer"
  type: "LoadBalancer"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: centralconsumer
  namespace: dataphos
  annotations:
    "syntio.net/logme": "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: centralconsumer
  template:
    metadata:
      labels:
        app: centralconsumer
      containers:
        - name: centralconsumer
          image: syntioinc/dataphos-schema-registry-validator:1.0.0
          resources:
            limits:
              cpu: "125m"
              memory: "80Mi"
            requests:
              cpu: "125m"
              memory: "40Mi"
          envFrom:
            - configMapRef:
                name: centralconsumer-config
          ports:
            - name: metrics
              containerPort: 2112
      imagePullSecrets:
        - name: nexuscred
---
```
{{< /details >}}

## Schema Registry Validator Kafka To Pubsub
{{< details "YAML example" >}}
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: dataphos
data:
  CONSUMER_TYPE: "kafka"
  CONSUMER_KAFKA_ADDRESS: $consumer_address # insert consumer bootstrap server here
  CONSUMER_KAFKA_TOPIC: $consumer_topic # insert consumer topic
  CONSUMER_KAFKA_GROUP_ID: $consumer_group_id # insert consumer group ID

  PRODUCER_TYPE: "pubsub"
  PRODUCER_PUBSUB_PROJECT_ID: $producer_project_ID # insert GCP project ID

  TOPICS_VALID: $producer_valid_topic_ID # insert producer valid topic
  TOPICS_DEAD_LETTER: $producer_deadletter_topic_ID # insert producer dead-letter topic

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_JSON: "true"
  VALIDATORS_ENABLE_AVRO: "false"
  VALIDATORS_ENABLE_PROTOBUF: "false"
  VALIDATORS_ENABLE_CSV: "false"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_ENABLE_XML: "false"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: dataphos
spec:
  ports:
    - name: metrics
      port: 2112
      targetPort: 2112
  selector:
    app: "centralconsumer"
  type: "LoadBalancer"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: centralconsumer
  namespace: dataphos
  annotations:
    "syntio.net/logme": "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: centralconsumer
  template:
    metadata:
      labels:
        app: centralconsumer
    spec:
      volumes:
        - name: google-cloud-key
          secret:
            secretName: service-account-credentials
      containers:
        - name: centralconsumer
          image: syntioinc/dataphos-schema-registry-validator:1.0.0
          resources:
            limits:
              cpu: "125m"
              memory: "80Mi"
            requests:
              cpu: "125m"
              memory: "40Mi"
          volumeMounts:
            - mountPath: /var/secrets/google
              name: google-cloud-key
          envFrom:
            - configMapRef:
                name: centralconsumer-config
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/secrets/google/key.json
          ports:
            - name: metrics
              containerPort: 2112
      imagePullSecrets:
        - name: nexuscred

---
```
{{< /details >}}

## Schema Registry Validator Pubsub
{{< details "YAML example" >}}

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: dataphos
data:
  CONSUMER_TYPE: "pubsub"
  CONSUMER_PUBSUB_PROJECT_ID: $consumer_project_ID # insert consumer GCP project ID
  CONSUMER_PUBSUB_SUBSCRIPTION_ID: $consumer_subscription_ID # insert producer pubsub subscription ID
  PRODUCER_TYPE: "pubsub"
  PRODUCER_PUBSUB_PROJECT_ID: $producer_project_ID # insert producer GCP project ID

  TOPICS_VALID: $producer_valid_topic_ID # insert producer valid topic
  TOPICS_DEAD_LETTER: $producer_deadletter_topic_ID # insert producer dead-letter topic

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_JSON: "true"
  VALIDATORS_ENABLE_AVRO: "false"
  VALIDATORS_ENABLE_PROTOBUF: "false"
  VALIDATORS_ENABLE_CSV: "false"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_ENABLE_XML: "false"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---

apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: dataphos
spec:
  ports:
    - name: metrics
      port: 2112
      targetPort: 2112
  selector:
    app: "centralconsumer"
  type: "LoadBalancer"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: centralconsumer
  namespace: dataphos
  annotations:
    "syntio.net/logme": "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: centralconsumer
  template:
    metadata:
      labels:
        app: centralconsumer
    spec:
      volumes:
        - name: google-cloud-key
          secret:
            secretName: service-account-credentials
      containers:
        - name: centralconsumer
          image: syntioinc/dataphos-schema-registry-validator:1.0.0
          resources:
            limits:
              cpu: "125m"
              memory: "80Mi"
            requests:
              cpu: "125m"
              memory: "40Mi"
          volumeMounts:
            - mountPath: /var/secrets/google
              name: google-cloud-key
          envFrom:
            - configMapRef:
                name: centralconsumer-config
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/secrets/google/key.json
          ports:
            - name: metrics
              containerPort: 2112
      imagePullSecrets:
        - name: nexuscred

---
```
{{< /details >}}

## Schema Registry Validator Service Bus
{{< details "YAML example" >}}

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: dataphos
data:
  CONSUMER_TYPE: "servicebus"
  CONSUMER_SERVICEBUS_CONNECTION_STRING: $consumer_servicebus_connection_string # insert the consumer service bus connection string
  CONSUMER_SERVICEBUS_TOPIC: consumer_servicebus_topic # insert te consumer service bus topic
  CONSUMER_SERVICEBUS_SUBSCRIPTION: $consumer_servicebus_subscription # insert te consumer service bus subsription

  PRODUCER_TYPE: "servicebus"
  PRODUCER_SERVICEBUS_CONNECTION_STRING: $producer_servicebus_connection_string # insert the producer service bus connection string

  TOPICS_VALID: $producer_valid_topic_ID # insert producer valid topic
  TOPICS_DEAD_LETTER: $producer_deadletter_topic_ID # insert producer dead-letter topic

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_JSON: "true"
  VALIDATORS_ENABLE_AVRO: "false"
  VALIDATORS_ENABLE_PROTOBUF: "false"
  VALIDATORS_ENABLE_CSV: "false"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_ENABLE_XML: "false"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: dataphos
spec:
  ports:
    - name: metrics
      port: 2112
      targetPort: 2112
  selector:
    app: "centralconsumer"
  type: "LoadBalancer"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: centralconsumer
  namespace: dataphos
  annotations:
    "syntio.net/logme": "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: centralconsumer
  template:
    metadata:
      labels:
        app: centralconsumer
    spec:
      containers:
        - name: centralconsumer
          image: syntioinc/dataphos-schema-registry-validator:1.0.0
          resources:
            limits:
              cpu: "125m"
              memory: "80Mi"
            requests:
              cpu: "125m"
              memory: "40Mi"
          envFrom:
            - configMapRef:
                name: centralconsumer-config
          ports:
            - name: metrics
              containerPort: 2112
      imagePullSecrets:
        - name: nexuscred

---
```
{{< /details >}}

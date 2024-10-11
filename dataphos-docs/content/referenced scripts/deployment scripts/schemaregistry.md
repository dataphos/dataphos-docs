---
title: "Schema Registry Scripts"
draft: false
---

# Dataphos Schema Registry

## Schema Registry API
{{< details "Schema Registry API" >}}
```
#!/bin/bash

if [ $# -ne 2 ]; then
        echo "please specify all required variables"
    exit 1
fi

namespace=$1
postgres_password=$2

kubectl apply -f - <<EOF

# Registry secrets
apiVersion: v1
kind: Secret
metadata:
  name: schema-registry-secret
  namespace: $namespace
type: Opaque
stringData:
  POSTGRES_PASSWORD: $postgres_password
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
  namespace: $namespace
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
  namespace: $namespace
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
            storage: 25Gi # todo check how much space it needs
---
# Registry service
apiVersion: "v1"
kind: "Service"
metadata:
  name: "schema-registry-svc"
  namespace: $namespace
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
  namespace: $namespace
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

EOF
```
{{< /details >}}
## Delete Schema Registry API
{{< details "Delete Script" >}}
```
#!/bin/bash

if [ $# -ne 1 ]; then
        echo "please specify all required variables"
    exit 1
fi

namespace=$1

kubectl delete -f - <<EOF

# Registry secrets
apiVersion: v1
kind: Secret
metadata:
  name: schema-registry-secret
  namespace: $namespace
type: Opaque
stringData:
  POSTGRES_PASSWORD: ""
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
  namespace: $namespace
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
  namespace: $namespace
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
            storage: 25Gi # todo check how much space it needs
---
# Registry service
apiVersion: "v1"
kind: "Service"
metadata:
  name: "schema-registry-svc"
  namespace: $namespace
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
  namespace: $namespace
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

EOF
```
{{< /details >}}
## Schema Registry Validator Kafka
{{< details "Deployment Script" >}}
```
#!/bin/bash

if [ $# -ne 8 ]; then
        echo "please specify all required variables"
    exit 1
fi

namespace=$1
producer_valid_topic_ID=$2
producer_deadletter_topic_ID=$3
message_type=$4
consumer_address=$5
consumer_topic=$6
consumer_group_id=$7
producer_address=$8

supported_message_types=("json", "avro", "protobuf", "xml", "csv")
if echo "${supported_message_types[@]}" | grep -qw "$message_type"; then
  echo "supported message type"
else
  echo "unsupported message type"
  exit 1
fi

deploy_xml_validator () {
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: xml-validator-svc
  labels:
    app: xml-validator-svc
spec:
  selector:
    app: xml-validator
  type: ClusterIP
  ports:
    - port: 8081
      targetPort: 8081
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xml-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: xml-validator
  template:
    metadata:
      labels:
        app: xml-validator
    spec:
      containers:
      - name: xml
        image: syntioinc/dataphos-schema-registry-xml-val:1.0.0
---
EOF
}

deploy_csv_validator () {
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: csv-validator-svc
  labels:
    app: csv-validator-svc
spec:
  selector:
    app: csv-validator
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: csv-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csv-validator
  template:
    metadata:
      labels:
        app: csv-validator
    spec:
      containers:
      - name: csv
        image: syntioinc/dataphos-schema-registry-csv-val:1.0.0
---
EOF
}

if [ "$message_type" = "csv" ]; then
    deploy_csv_validator
elif [ "$message_type" = "xml" ]; then
    deploy_xml_validator
fi

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: $namespace
data:
  CONSUMER_TYPE: "kafka"
  CONSUMER_KAFKA_ADDRESS: $consumer_address
  CONSUMER_KAFKA_TOPIC: $consumer_topic
  CONSUMER_KAFKA_GROUP_ID: $consumer_group_id

  PRODUCER_TYPE: "kafka"
  PRODUCER_KAFKA_ADDRESS: $producer_address

  TOPICS_VALID: $producer_valid_topic_ID
  TOPICS_DEAD_LETTER: $producer_deadletter_topic_ID

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_${message_type^^}: "true"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: $namespace
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
  namespace: $namespace
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
EOF
```
{{< /details >}}

## Delete Schema Registry Validator Kafka
{{< details "Deletion Script" >}}

```
#!/bin/bash

if [ $# -ne 2 ]; then
        echo "please specify all required variables"
    exit 1
fi

namespace=$1
message_type=$2

supported_message_types=("json", "avro", "protobuf", "xml", "csv")
if echo "${supported_message_types[@]}" | grep -qw "$message_type"; then
  echo "supported message type"
else
  echo "unsupported message type"
  exit 1
fi

delete_xml_validator () {
  kubectl delete -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: xml-validator-svc
  labels:
    app: xml-validator-svc
spec:
  selector:
    app: xml-validator
  type: ClusterIP
  ports:
    - port: 8081
      targetPort: 8081
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xml-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: xml-validator
  template:
    metadata:
      labels:
        app: xml-validator
    spec:
      containers:
      - name: xml
        image: syntioinc/dataphos-schema-registry-xml-val:1.0.0
---
EOF
}

delete_csv_validator () {
  kubectl delete -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: csv-validator-svc
  labels:
    app: csv-validator-svc
spec:
  selector:
    app: csv-validator
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: csv-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csv-validator
  template:
    metadata:
      labels:
        app: csv-validator
    spec:
      containers:
      - name: csv
        image: syntioinc/dataphos-schema-registry-csv-val:1.0.0
---
EOF
}

if [ "$message_type" = "csv" ]; then
    delete_csv_validator
elif [ "$message_type" = "xml" ]; then
    delete_xml_validator
fi

kubectl delete -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: $namespace
data:
  CONSUMER_TYPE: "kafka"
  CONSUMER_KAFKA_ADDRESS: ""
  CONSUMER_KAFKA_TOPIC: ""
  CONSUMER_KAFKA_GROUP_ID: ""

  PRODUCER_TYPE: "kafka"
  PRODUCER_KAFKA_ADDRESS: ""

  TOPICS_VALID: ""
  TOPICS_DEAD_LETTER: ""

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_${message_type^^}: "true"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: $namespace
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
  namespace: $namespace
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
EOF
```
{{< /details >}}

## Schema Registry Validator Kafka to PubSub
{{< details "Deployment Script" >}}

```
#!/bin/bash

if [ $# -ne 8 ]; then
        echo "please specify all required variables"
    exit 1
fi

namespace=$1
producer_valid_topic_ID=$2
producer_deadletter_topic_ID=$3
message_type=$4
consumer_address=$5
consumer_topic=$6
consumer_group_id=$7
producer_project_ID=$8

supported_message_types=("json", "avro", "protobuf", "xml", "csv")
if echo "${supported_message_types[@]}" | grep -qw "$message_type"; then
  echo "supported message type"
else
  echo "unsupported message type"
  exit 1
fi

deploy_xml_validator () {
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: xml-validator-svc
  labels:
    app: xml-validator-svc
spec:
  selector:
    app: xml-validator
  type: ClusterIP
  ports:
    - port: 8081
      targetPort: 8081
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xml-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: xml-validator
  template:
    metadata:
      labels:
        app: xml-validator
    spec:
      containers:
      - name: xml
        image: syntioinc/dataphos-schema-registry-xml-val:1.0.0
---
EOF
}

deploy_csv_validator () {
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: csv-validator-svc
  labels:
    app: csv-validator-svc
spec:
  selector:
    app: csv-validator
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: csv-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csv-validator
  template:
    metadata:
      labels:
        app: csv-validator
    spec:
      containers:
      - name: csv
        image: syntioinc/dataphos-schema-registry-csv-val:1.0.0
---
EOF
}

if [ "$message_type" = "csv" ]; then
    deploy_csv_validator
elif [ "$message_type" = "xml" ]; then
    deploy_xml_validator
fi

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: $namespace
data:
  CONSUMER_TYPE: "kafka"
  CONSUMER_KAFKA_ADDRESS: $consumer_address
  CONSUMER_KAFKA_TOPIC: $consumer_topic
  CONSUMER_KAFKA_GROUP_ID: $consumer_group_id

  PRODUCER_TYPE: "pubsub"
  PRODUCER_PUBSUB_PROJECT_ID: $producer_project_ID

  TOPICS_VALID: $producer_valid_topic_ID
  TOPICS_DEAD_LETTER: $producer_deadletter_topic_ID

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_${message_type^^}: "true"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: $namespace
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
  namespace: $namespace
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
EOF
```
{{< /details >}}

## Delete Schema Registry Validator Kafka to PubSub
{{< details "Deletion Script" >}}

```
#!/bin/bash

if [ $# -ne 2 ]; then
        echo "please specify all required variables"
    exit 1
fi

namespace=$1
message_type=$2


supported_message_types=("json", "avro", "protobuf", "xml", "csv")
if echo "${supported_message_types[@]}" | grep -qw "$message_type"; then
  echo "supported message type"
else
  echo "unsupported message type"
  exit 1
fi

delete_xml_validator () {
  kubectl delete -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: xml-validator-svc
  labels:
    app: xml-validator-svc
spec:
  selector:
    app: xml-validator
  type: ClusterIP
  ports:
    - port: 8081
      targetPort: 8081
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xml-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: xml-validator
  template:
    metadata:
      labels:
        app: xml-validator
    spec:
      containers:
      - name: xml
        image: syntioinc/dataphos-schema-registry-xml-val:1.0.0
---
EOF
}

delete_csv_validator () {
  kubectl delete -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: csv-validator-svc
  labels:
    app: csv-validator-svc
spec:
  selector:
    app: csv-validator
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: csv-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csv-validator
  template:
    metadata:
      labels:
        app: csv-validator
    spec:
      containers:
      - name: csv
        image: syntioinc/dataphos-schema-registry-csv-val:1.0.0
---
EOF
}

if [ "$message_type" = "csv" ]; then
    delete_csv_validator
elif [ "$message_type" = "xml" ]; then
    delete_xml_validator
fi

kubectl delete -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: $namespace
data:
  CONSUMER_TYPE: "kafka"
  CONSUMER_KAFKA_ADDRESS: ""
  CONSUMER_KAFKA_TOPIC: ""
  CONSUMER_KAFKA_GROUP_ID: ""

  PRODUCER_TYPE: "pubsub"
  PRODUCER_PUBSUB_PROJECT_ID: ""

  TOPICS_VALID: ""
  TOPICS_DEAD_LETTER: ""

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_${message_type^^}: "true"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: $namespace
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
  namespace: $namespace
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
EOF
```
{{< /details >}}

## Schema Registry Validator PubSub
{{< details "Deployment Script" >}}

```
#!/bin/bash

if [ $# -ne 7 ]; then
        echo "please specify all required variables"
    exit 1
fi

namespace=$1
producer_valid_topic_ID=$2
producer_deadletter_topic_ID=$3
message_type=$4
consumer_project_ID=$5
consumer_subscription_ID=$6
producer_project_ID=$7
path_to_key_file=$8

kubectl create secret generic service-account-credentials -n dataphos --from-file=key.json=$path_to_key_file

# shellcheck disable=SC2054
supported_message_types=("json", "avro", "protobuf", "xml", "csv")
if echo "${supported_message_types[@]}" | grep -qw "$message_type"; then
  echo "supported message type"
else
  echo "unsupported message type"
  exit 1
fi

deploy_xml_validator () {
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: xml-validator-svc
  labels:
    app: xml-validator-svc
spec:
  selector:
    app: xml-validator
  type: ClusterIP
  ports:
    - port: 8081
      targetPort: 8081
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xml-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: xml-validator
  template:
    metadata:
      labels:
        app: xml-validator
    spec:
      containers:
      - name: xml
        image: syntioinc/dataphos-schema-registry-xml-val:1.0.0
---
EOF
}

deploy_csv_validator () {
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: csv-validator-svc
  labels:
    app: csv-validator-svc
spec:
  selector:
    app: csv-validator
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: csv-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csv-validator
  template:
    metadata:
      labels:
        app: csv-validator
    spec:
      containers:
      - name: csv
        image: syntioinc/dataphos-schema-registry-csv-val:1.0.0
---
EOF
}

if [ "$message_type" = "csv" ]; then
    deploy_csv_validator
elif [ "$message_type" = "xml" ]; then
    deploy_xml_validator
fi

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: $namespace
data:
  CONSUMER_TYPE: "pubsub"
  CONSUMER_PUBSUB_PROJECT_ID: $consumer_project_ID
  CONSUMER_PUBSUB_SUBSCRIPTION_ID: $consumer_subscription_ID
  PRODUCER_TYPE: "pubsub"
  PRODUCER_PUBSUB_PROJECT_ID: $producer_project_ID

  TOPICS_VALID: $producer_valid_topic_ID
  TOPICS_DEAD_LETTER: $producer_deadletter_topic_ID

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_${message_type^^}: "true"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---

apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: $namespace
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
  namespace: $namespace
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
EOF
```
{{< /details >}}

## Delete Schema Registry Validator PubSub
{{< details "Deletion Script" >}}

```
#!/bin/bash

if [ $# -ne 2 ]; then
        echo "please specify all required variables"
    exit 1
fi

namespace=$1
message_type=$2

# shellcheck disable=SC2054
supported_message_types=("json", "avro", "protobuf", "xml", "csv")
if echo "${supported_message_types[@]}" | grep -qw "$message_type"; then
  echo "supported message type"
else
  echo "unsupported message type"
  exit 1
fi

delete_xml_validator () {
  kubectl delete -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: xml-validator-svc
  labels:
    app: xml-validator-svc
spec:
  selector:
    app: xml-validator
  type: ClusterIP
  ports:
    - port: 8081
      targetPort: 8081
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xml-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: xml-validator
  template:
    metadata:
      labels:
        app: xml-validator
    spec:
      containers:
      - name: xml
        image: syntioinc/dataphos-schema-registry-xml-val:1.0.0
---
EOF
}

delete_csv_validator () {
  kubectl delete -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: csv-validator-svc
  labels:
    app: csv-validator-svc
spec:
  selector:
    app: csv-validator
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: csv-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csv-validator
  template:
    metadata:
      labels:
        app: csv-validator
    spec:
      containers:
      - name: csv
        image: syntioinc/dataphos-schema-registry-csv-val:1.0.0
---
EOF
}

if [ "$message_type" = "csv" ]; then
    delete_csv_validator
elif [ "$message_type" = "xml" ]; then
    delete_xml_validator
fi

kubectl delete -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: $namespace
data:
  CONSUMER_TYPE: "pubsub"
  CONSUMER_PUBSUB_PROJECT_ID: ""
  CONSUMER_PUBSUB_SUBSCRIPTION_ID: ""
  PRODUCER_TYPE: "pubsub"
  PRODUCER_PUBSUB_PROJECT_ID: ""

  TOPICS_VALID: ""
  TOPICS_DEAD_LETTER: ""

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_${message_type^^}: "true"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---

apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: $namespace
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
  namespace: $namespace
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
EOF
```
{{< /details >}}

## Schema Registry Validator ServiceBus
{{< details "Deployment Script" >}}

```
#!/bin/bash

if [ $# -ne 8 ]; then
        echo "please specify all required variables"
    exit 1
fi

namespace=$1
producer_valid_topic_ID=$2
producer_deadletter_topic_ID=$3
message_type=$4
consumer_servicebus_connection_string=$5
consumer_servicebus_topic=$6
consumer_servicebus_subscription=$7
producer_servicebus_connection_string=$8

supported_message_types=("json", "avro", "protobuf", "xml", "csv")
if echo "${supported_message_types[@]}" | grep -qw "$message_type"; then
  echo "supported message type"
else
  echo "unsupported message type"
  exit 1
fi

deploy_xml_validator () {
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: xml-validator-svc
  labels:
    app: xml-validator-svc
spec:
  selector:
    app: xml-validator
  type: ClusterIP
  ports:
    - port: 8081
      targetPort: 8081
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xml-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: xml-validator
  template:
    metadata:
      labels:
        app: xml-validator
    spec:
      containers:
      - name: xml
        image: syntioinc/dataphos-schema-registry-xml-val:1.0.0
---
EOF
}

deploy_csv_validator () {
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: csv-validator-svc
  labels:
    app: csv-validator-svc
spec:
  selector:
    app: csv-validator
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: csv-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csv-validator
  template:
    metadata:
      labels:
        app: csv-validator
    spec:
      containers:
      - name: csv
        image: syntioinc/dataphos-schema-registry-csv-val:1.0.0
---
EOF
}

if [ "$message_type" = "csv" ]; then
    deploy_csv_validator
elif [ "$message_type" = "xml" ]; then
    deploy_xml_validator
fi

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: $namespace
data:
  CONSUMER_TYPE: "servicebus"
  CONSUMER_SERVICEBUS_CONNECTION_STRING: $consumer_servicebus_connection_string
  CONSUMER_SERVICEBUS_TOPIC: $consumer_servicebus_topic
  CONSUMER_SERVICEBUS_SUBSCRIPTION: $consumer_servicebus_subscription

  PRODUCER_TYPE: "servicebus"
  PRODUCER_SERVICEBUS_CONNECTION_STRING: $producer_servicebus_connection_string

  TOPICS_VALID: $producer_valid_topic_ID
  TOPICS_DEAD_LETTER: $producer_deadletter_topic_ID

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_${message_type^^}: "true"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: $namespace
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
  namespace: $namespace
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
EOF
```
{{< /details >}}

## Delete Schema Registry Validator ServiceBus
{{< details "Deletion Script" >}}

```
#!/bin/bash

if [ $# -ne 2 ]; then
        echo "please specify all required variables"
    exit 1
fi

namespace=$1
message_type=$2

supported_message_types=("json", "avro", "protobuf", "xml", "csv")
if echo "${supported_message_types[@]}" | grep -qw "$message_type"; then
  echo "supported message type"
else
  echo "unsupported message type"
  exit 1
fi

delete_xml_validator () {
  kubectl delete -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: xml-validator-svc
  labels:
    app: xml-validator-svc
spec:
  selector:
    app: xml-validator
  type: ClusterIP
  ports:
    - port: 8081
      targetPort: 8081
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xml-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: xml-validator
  template:
    metadata:
      labels:
        app: xml-validator
    spec:
      containers:
      - name: xml
        image: syntioinc/dataphos-schema-registry-xml-val:1.0.0
---
EOF
}

delete_csv_validator () {
  kubectl delete -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: csv-validator-svc
  labels:
    app: csv-validator-svc
spec:
  selector:
    app: csv-validator
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: csv-validator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csv-validator
  template:
    metadata:
      labels:
        app: csv-validator
    spec:
      containers:
      - name: csv
        image: syntioinc/dataphos-schema-registry-csv-val:1.0.0
---
EOF
}

if [ "$message_type" = "csv" ]; then
    delete_csv_validator
elif [ "$message_type" = "xml" ]; then
    delete_xml_validator
fi

kubectl delete -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: centralconsumer-config
  namespace: $namespace
data:
  CONSUMER_TYPE: "servicebus"
  CONSUMER_SERVICEBUS_CONNECTION_STRING: ""
  CONSUMER_SERVICEBUS_TOPIC: consumer_servicebus_topic
  CONSUMER_SERVICEBUS_SUBSCRIPTION: ""

  PRODUCER_TYPE: "servicebus"
  PRODUCER_SERVICEBUS_CONNECTION_STRING: ""

  TOPICS_VALID: ""
  TOPICS_DEAD_LETTER: ""

  REGISTRY_URL: "http://schema-registry-svc:8080"
  VALIDATORS_ENABLE_${message_type^^}: "true"
  VALIDATORS_CSV_URL: "http://csv-validator-svc:8080"
  VALIDATORS_XML_URL: "http://xml-validator-svc:8081"

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "metrics"
  namespace: $namespace
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
  namespace: $namespace
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
EOF
```
{{< /details >}}

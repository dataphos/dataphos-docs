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
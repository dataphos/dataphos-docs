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

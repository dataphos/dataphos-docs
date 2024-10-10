#!/bin/bash

Help()
{
echo "Flags:"
echo "-n - the namespace where Publisher will be deployed"
echo "-u - username for the Postgres metadata database"
echo "-p - password for the Postgres metadata database"
}

if [ $# -eq 1 ] & [ $1 == "--help" ]; then
    Help
    exit
fi

if [ $# -ne 6 ]; then
  echo "Please specify all required variables"
  exit 1
fi

while getopts n:u:p: flag
do
    case "${flag}" in
        n) namespace=${OPTARG};;
        u) postgres_user=${OPTARG};;
        p) postgres_password=${OPTARG};;
    esac
done

kubectl apply -f - <<EOF
# Manager and Web UI services
apiVersion: v1
kind: Service
metadata:
  name: publisher-manager
  namespace: $namespace
spec:
  selector:
    app: server
    component: manager
  ports:
    - port: 8080
      targetPort: 8080
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: publisher-webui
  namespace: $namespace
spec:
  selector:
    app: webui
    component: webui
  ports:
    - port: 8080
  type: LoadBalancer
---
# Postgres metadata database
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-postgres-config
  namespace: $namespace
data:
  PGDATA: /var/lib/postgresql/data/pgdata
---
apiVersion: v1
kind: Secret
metadata:
  name: publisher-postgres-secret
  namespace: $namespace
type: Opaque
stringData:
  POSTGRES_USER: $postgres_user
  POSTGRES_PASSWORD: $postgres_password
---
apiVersion: v1
kind: Service
metadata:
  name: publisher-postgres
  namespace: $namespace
spec:
  selector:
    app: publisher-postgres-db
  ports:
    - port: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: publisher-postgres-db
  namespace: $namespace
spec:
  serviceName: publisher-postgres
  replicas: 1
  selector:
    matchLabels:
      app: publisher-postgres-db
  template:
    metadata:
      labels:
        app: publisher-postgres-db
    spec:
      containers:
        - name: publisher-postgres
          image: postgres:latest
          ports:
            - containerPort: 5432
          envFrom:
            - configMapRef:
                name: publisher-postgres-config
            - secretRef:
                name: publisher-postgres-secret
          volumeMounts:
            - name: publisher-postgres-volume
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: publisher-postgres-volume
        namespace: $namespace
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 20Gi
---
# Common configuration
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-metadata-config
  namespace: $namespace
data:
  METADATA_HOST: publisher-postgres
  METADATA_PORT: "5432"
  METADATA_DATABASE: publisher_metadata
---
apiVersion: v1
kind: Secret
metadata:
  name: publisher-metadata-secret
  namespace: $namespace
type: Opaque
stringData:
  METADATA_USERNAME: $postgres_user # insert your database username
  METADATA_PASSWORD: $postgres_password # insert your database user password
---
# optional secret
apiVersion: v1
kind: Secret
metadata:
  name: pubsub-key
  namespace: $namespace
type: Opaque
data:
  "key.json": "" # insert your base64 encoded Pub/Sub service account key, leave empty if publishing to Pub/Sub
  # not needed (optional)
---
# optional secret
apiVersion: v1
kind: Secret
metadata:
  name: kafka-tls-credentials
  namespace: $namespace
type: Opaque
data:
  "ca_crt.pem": "" # insert your base64 encoded Kafka cluster CA TLS certificate, leave empty if not needed (optional)
  "client_crt.pem": "" # insert your base64 encoded Kafka user TLS certificate, leave empty if not needed (optional)
  "client_key.pem": "" # insert your base64 encoded Kafka user TLS private key, leave empty if not needed (optional)
---
# optional secret
apiVersion: v1
kind: Secret
metadata:
  name: nats-tls-credentials
  namespace: $namespace
type: Opaque
data:
  "ca_crt.pem": "" # insert your base64 encoded Nats cluster CA TLS certificate, leave empty if not needed (optional)
  "client_crt.pem": "" # insert your base64 encoded Nats user TLS certificate, leave empty if not needed (optional)
  "client_key.pem": "" # insert your base64 encoded Nats user TLS private key, leave empty if not needed (optional)
---
# optional secret
apiVersion: v1
kind: Secret
metadata:
  name: pulsar-tls-credentials
  namespace: $namespace
type: Opaque
data:
  "ca_crt.pem": "" # insert your base64 encoded Nats cluster CA TLS certificate, leave empty if not needed (optional)
  "client_crt.pem": "" # insert your base64 encoded Nats user TLS certificate, leave empty if not needed (optional)
  "client_key.pem": "" # insert your base64 encoded Nats user TLS private key, leave empty if not needed (optional)
---
apiVersion: v1
kind: Secret
metadata:
  name: encryption-keys
  namespace: $namespace
type: Opaque
stringData:       # insert your encryption keys, one or more
  "keys.yaml": |
    ENC_KEY_1: "D2C0B5865AE141A49816F1FDC110FA5A"
---
# Initialize metadata database
apiVersion: batch/v1
kind: Job
metadata:
  name: publisher-initdb
  namespace: $namespace
spec:
  template:
    spec:
      containers:
        - name: initdb
          image: syntioinc/dataphos-publisher-initdb:1.0.0
          ports:
            - containerPort: 5432
          envFrom:
            - configMapRef:
                name: publisher-metadata-config
            - secretRef:
                name: publisher-metadata-secret
      restartPolicy: OnFailure
  backoffLimit: 15
---
# Avro Schema Generator
apiVersion: v1
kind: Service
metadata:
  name: publisher-avro-schema-generator
  namespace: $namespace
spec:
  selector:
    app: server
    component: avro-schema-generator
  ports:
    - protocol: TCP
      port: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-avro-schema-generator
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: server
      component: avro-schema-generator
  template:
    metadata:
      labels:
        app: server
        component: avro-schema-generator
      annotations:
        syntio.net/logme: "true"
    spec:
      containers:
        - name: avro-schema-generator
          image: syntioinc/dataphos-publisher-avro-schema-generator:1.0.0
          resources:
            limits:
              cpu: 500m
            requests:
              cpu: 50m
              memory: 250Mi
---
# Kubernetes Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: publisher-sa
  namespace: $namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: publisher-sa-role
  namespace: $namespace
rules:
  - apiGroups: [""] # "" indicates the core API group
    resources: ["pods"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: publisher-sa-rb
  namespace: $namespace
subjects:
  - kind: ServiceAccount
    name: publisher-sa
roleRef:
  kind: Role
  name: publisher-sa-role
  apiGroup: rbac.authorization.k8s.io
---
# Scheduler
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-scheduler-config
  namespace: $namespace
data:
  WORKER_IMAGE: syntioinc/dataphos-publisher-worker:1.0.0
  FETCHER_URL: http://publisher-data-fetcher:8081
  SCHEMA_GENERATOR_URL: http://publisher-avro-schema-generator:8080
  SCHEMA_VALIDATION_URL: "" # insert the schema registry public URL or an empty string if schema registry is not deployed
  IMAGE_PULL_SECRET: regcred
  KUBERNETES_NAMESPACE: $namespace
  SECRET_NAME_PUBSUB: pubsub-key
  SECRET_NAME_KAFKA: kafka-tls-credentials
  SECRET_NAME_NATS: nats-tls-credentials
  SECRET_NAME_PULSAR: pulsar-tls-credentials
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-scheduler
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: server
      component: scheduler
  template:
    metadata:
      labels:
        app: server
        component: scheduler
      annotations:
        syntio.net/logme: "true"
    spec:
      serviceAccountName: publisher-sa
      containers:
        - name: scheduler
          image: syntioinc/dataphos-publisher-scheduler:1.0.0
          resources:
            limits:
              cpu: 100m
            requests:
              cpu: 5m
              memory: 30Mi
          envFrom:
            - configMapRef:
                name: publisher-scheduler-config
            - configMapRef:
                name: publisher-metadata-config
            - secretRef:
                name: publisher-metadata-secret
---
EOF

while [ -z "$webui_ip" ]
do
  webui_ip=$(kubectl get services --namespace "$namespace" publisher-webui --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
  echo "Waiting for Web UI service to be created..."
  sleep 5
done

kubectl apply -f - <<EOF
# Manager
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-manager-config
  namespace: $namespace
data:
  WEB_UI: http://$webui_ip:8080
  FETCHER_URL: http://publisher-data-fetcher:8081
---
apiVersion: v1
kind: Secret
metadata:
  name: publisher-manager-secret
  namespace: $namespace
type: Opaque
stringData:
  JWT_SECRET: "DuperSecretPass!" # insert your JWT secret key, 16 characters
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-manager
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: server
      component: manager
  template:
    metadata:
      labels:
        app: server
        component: manager
      annotations:
        syntio.net/logme: "true"
    spec:
      containers:
        - name: manager
          image: syntioinc/dataphos-publisher-manager:1.0.0
          resources:
            limits:
              cpu: 100m
            requests:
              cpu: 5m
              memory: 45Mi
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: publisher-manager-config
            - secretRef:
                name: publisher-manager-secret
            - configMapRef:
                name: publisher-metadata-config
            - secretRef:
                name: publisher-metadata-secret
---
# WebUI
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-webui-config
  namespace: $namespace
data:  # insert your manager domain name
  "server.properties": |
    window.MANAGER_ENDPOINT = "/backend"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-webui
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webui
      component: webui
  template:
    metadata:
      labels:
        app: webui
        component: webui
    spec:
      containers:
        - name: manager
          image: syntioinc/dataphos-publisher-webui:1.0.0
          resources:
            limits:
              cpu: 100m
            requests:
              cpu: 5m
              memory: 30Mi
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: publisher-webui-config-volume
              mountPath: /usr/share/nginx/html/config.js
              subPath: config.js
      volumes:
        - name: publisher-webui-config-volume
          configMap:
            name: publisher-webui-config
            items:
              - key: server.properties
                path: config.js
---
EOF

kubectl apply -f - <<EOF
# Data Fetcher
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-data-fetcher-config
  namespace: $namespace
data:
  MANAGER_URL: http://publisher-manager:8080
---
apiVersion: v1
kind: Service
metadata:
  name: publisher-data-fetcher
  namespace: $namespace
spec:
  selector:
    app: server
    component: data-fetcher
  ports:
    - protocol: TCP
      port: 8081
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-data-fetcher
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: server
      component: data-fetcher
  template:
    metadata:
      labels:
        app: server
        component: data-fetcher
      annotations:
        syntio.net/logme: "true"
    spec:
      containers:
        - name: data-fetcher
          image: syntioinc/dataphos-publisher-data-fetcher:1.0.0
          resources:
            limits:
              cpu: 600m
            requests:
              cpu: 200m
              memory: 160Mi
          ports:
            - containerPort: 8081
          envFrom:
            - configMapRef:
                name: publisher-data-fetcher-config
---
EOF
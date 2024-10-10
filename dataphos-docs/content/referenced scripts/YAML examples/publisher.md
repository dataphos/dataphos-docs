---
title: "Publisher Examples"
draft: true
weight: 3
---

# Dataphos Publisher

## Publisher Ingress
{{< details "YAML example" >}}

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: publisher-webui-ingress
  namespace: dataphos
  annotations:
    kubernetes.io/ingress.class : nginx
    nginx.ingress.kubernetes.io/ssl-redirect : "true"
    nginx.ingress.kubernetes.io/enable-cors : "true"
    nginx.ingress.kubernetes.io/cors-allow-methods : "PUT, GET, POST, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-origin : "*"
    nginx.ingress.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
spec:
  rules:
    - host: <webui-domain-name> # insert your WEB UI domain name, same as in the Manager config map
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: publisher-webui
                port:
                  number: 8080
  tls:
    - hosts:
        - <webui-domain-name> # insert your WEB UI domain name
      secretName: webui-tls-secret
```
{{< /details >}}

## Publisher PostgreSQL Deployment
{{< details "YAML example" >}}

```
apiVersion: v1
kind: Namespace
metadata:
  name: publisher-source
---

apiVersion: v1
kind: ConfigMap
metadata:
  name: publisher-postgres-source-config
  namespace: publisher-source
data:
  PGDATA: /var/lib/postgresql/data/pgdata
---

apiVersion: v1
kind: Secret
metadata:
  name: publisher-postgres-source-secret
  namespace: publisher-source
type: Opaque
stringData:
  POSTGRES_DB: invoices
  POSTGRES_USER: demo_user
  POSTGRES_PASSWORD: demo_password
---

apiVersion: v1
kind: Service
metadata:
  name: publisher-postgres-source
  namespace: publisher-source
spec:
  selector:
    app: publisher-postgres-source-db
  ports:
    - port: 5432
  type: LoadBalancer
---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: publisher-postgres-source-db
  namespace: publisher-source
spec:
  serviceName: publisher-postgres-source
  replicas: 1
  selector:
    matchLabels:
      app: publisher-postgres-source-db
  template:
    metadata:
      labels:
        app: publisher-postgres-source-db
    spec:
      containers:
        - name: publisher-postgres-source
          image: syntioinc/dataphos-publisher-source-example:1.0.0
          ports:
            - containerPort: 5432
          envFrom:
            - configMapRef:
                name: publisher-postgres-source-config
            - secretRef:
                name: publisher-postgres-source-secret
          volumeMounts:
            - name: publisher-postgres-source-data-volume
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: publisher-postgres-source-data-volume
        namespace: publisher-source
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 500M
```
{{< /details >}}

## Publisher k8s
{{< details "YAML example" >}}

```
# Postgres metadata database
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-postgres-config
  namespace: dataphos
data:
  PGDATA: /var/lib/postgresql/data/pgdata
---

apiVersion: v1
kind: Secret
metadata:
  name: publisher-postgres-secret
  namespace: dataphos
type: Opaque
stringData:
  POSTGRES_DB: publisher # insert your database name, same as METADATA_DATABASE in configuration.yaml
  POSTGRES_USER: publisher # insert your database username, same as METADATA_USERNAME in configuration.yaml
  POSTGRES_PASSWORD: samplePassworD1212 # insert your database user password, same as METADATA_PASSWORD in configuration.yaml
---


# Common configuration
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-metadata-config
  namespace: dataphos
data:
  METADATA_HOST: publisher-postgres.dataphos.svc
  METADATA_PORT: "5432"
  METADATA_DATABASE: publisher_metadata
---

apiVersion: v1
kind: Secret
metadata:
  name: publisher-metadata-secret
  namespace: dataphos
type: Opaque
stringData:
  METADATA_USERNAME: publisher # insert your database username
  METADATA_PASSWORD: samplePassworD1212 # insert your database user password
---

# optional secret
apiVersion: v1
kind: Secret
metadata:
  name: kafka-tls-credentials
  namespace: dataphos
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
  namespace: dataphos
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
  namespace: dataphos
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
  name: pubsub-key
  namespace: dataphos
type: Opaque
data:
  "key.json": "" # insert your base64 encoded Pub/Sub service account key, leave empty if publishing to Pub/Sub
  # not needed (optional)
---

apiVersion: v1
kind: Secret
metadata:
  name: encryption-keys
  namespace: dataphos
type: Opaque
stringData:       # insert your encryption keys, one or more
  "keys.yaml": |
    ENC_KEY_1: "D2C0B5865AE141A49816F1FDC110FA5A"
---
# Manager
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-manager-config
  namespace: dataphos
data:
  WEB_UI: <webui-domain-name> # insert your webui domain name
  FETCHER_URL: http://publisher-data-fetcher:8081
---

apiVersion: v1
kind: Secret
metadata:
  name: publisher-manager-secret
  namespace: dataphos
type: Opaque
stringData:
  JWT_SECRET: SuperSecretPass!  # insert your JWT secret key, 16 characters
---

# Data Fetcher
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-data-fetcher-config
  namespace: dataphos
data:
  MANAGER_URL: http://publisher-manager:8080
---

# Scheduler
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-scheduler-config
  namespace: dataphos
data:
  WORKER_IMAGE: syntioinc/dataphos-publisher-worker:1.0.0
  FETCHER_URL: http://publisher-data-fetcher:8081
  SCHEMA_GENERATOR_URL: http://publisher-avro-schema-generator:8080
  SCHEMA_VALIDATION_URL: http:/<ip-address> # insert the schema registry public URL or 0.0.0.0 if schema registry is not deployed
  IMAGE_PULL_SECRET: regcred
  KUBERNETES_NAMESPACE: dataphos
  SECRET_NAME_PUBSUB: pubsub-key
  SECRET_NAME_KAFKA: kafka-tls-credentials
  SECRET_NAME_NATS: nats-tls-credentials
  SECRET_NAME_PULSAR: pulsar-tls-credentials
---

# WebUI
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-webui-config
  namespace: dataphos
data:
  "server.properties": |
    window.MANAGER_ENDPOINT = "/backend"
---

apiVersion: v1
kind: Service
metadata:
  name: publisher-postgres
  namespace: dataphos
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
  namespace: dataphos
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
        namespace: publisher
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 20Gi
---

# Initialize metadata database
apiVersion: batch/v1
kind: Job
metadata:
  name: publisher-initdb
  namespace: dataphos
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
  namespace: dataphos
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
  namespace: dataphos
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

apiVersion: v1
kind: Service
metadata:
  name: publisher-manager
  namespace: dataphos
spec:
  selector:
    app: server
    component: manager
  ports:
    - port: 8080
      targetPort: 8080
  type: ClusterIP
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-manager
  namespace: dataphos
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

apiVersion: v1
kind: Service
metadata:
  name: publisher-data-fetcher
  namespace: dataphos
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
  namespace: dataphos
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
      initContainers:
        - name: check-manager-health
          image: curlimages/curl:7.85.0
          command: ['sh', '-c', 'while [ `curl -s -o /dev/null -w "%{http_code}" http://publisher-manager:8080` -ne 200 ]; do echo waiting for manager to be ready...; sleep 10; done;']
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


# Kubernetes Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: publisher-sa
  namespace: dataphos
---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: publisher-sa-role
  namespace: dataphos
rules:
  - apiGroups: [""] # "" indicates the core API group
    resources: ["pods"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: publisher-sa-rb
  namespace: dataphos
subjects:
  - kind: ServiceAccount
    name: publisher-sa
roleRef:
  kind: Role
  name: publisher-sa-role
  apiGroup: rbac.authorization.k8s.io
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-scheduler
  namespace: dataphos
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

apiVersion: v1
kind: Service
metadata:
  name: publisher-webui
  namespace: dataphos
spec:
  selector:
    app: webui
    component: webui
  ports:
    - port: 8080
  type: NodePort
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-webui
  namespace: dataphos
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
```
{{< /details >}}


## Publisher GCP
{{< details "YAML example" >}}

```
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: dataphos
---

# Postgres metadata database
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-postgres-config
  namespace: dataphos
data:
  PGDATA: /var/lib/postgresql/data/pgdata
---

apiVersion: v1
kind: Secret
metadata:
  name: publisher-postgres-secret
  namespace: dataphos
type: Opaque
stringData:
  POSTGRES_DB: dataphos_publisher # insert your database name, same as METADATA_DATABASE in configuration.yaml
  POSTGRES_USER: publisher # insert your database username, same as METADATA_USERNAME in configuration.yaml
  POSTGRES_PASSWORD: samplePassworD1212 # insert your database user password, same as METADATA_PASSWORD in configuration.yaml
---

# Common configuration
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-metadata-config
  namespace: dataphos
data:
  METADATA_HOST: publisher-postgres.dataphos.svc
  METADATA_PORT: "5432"
  METADATA_DATABASE: publisher_metadata
---

apiVersion: v1
kind: Secret
metadata:
  name: publisher-metadata-secret
  namespace: dataphos
type: Opaque
stringData:
  METADATA_USERNAME: publisher # insert your database username
  METADATA_PASSWORD: samplePassworD1212 # insert your database user password
---

# optional secret
apiVersion: v1
kind: Secret
metadata:
  name: pubsub-key
  namespace: dataphos
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
  namespace: dataphos
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
  namespace: dataphos
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
  namespace: dataphos
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
  namespace: dataphos
type: Opaque
stringData:       # insert your encryption keys, one or more
  "keys.yaml": |
    ENC_KEY_1: "D2C0B5865AE141A49816F1FDC110FA5A"
---

# Manager
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-manager-config
  namespace: dataphos
data:
  WEB_UI: https://<webui-domain-name> # insert your webui domain name
  FETCHER_URL: http://publisher-data-fetcher:8081
---

apiVersion: v1
kind: Secret
metadata:
  name: publisher-manager-secret
  namespace: dataphos
type: Opaque
stringData:
  JWT_SECRET: SuperSecretPass! # insert your JWT secret key, 16 characters
---

# Data Fetcher
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-data-fetcher-config
  namespace: dataphos
data:
  MANAGER_URL: http://publisher-manager:8080
---

# Scheduler
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-scheduler-config
  namespace: dataphos
data:
  WORKER_IMAGE: syntioinc/dataphos-publisher-worker:1.0.0
  FETCHER_URL: http://publisher-data-fetcher:8081
  SCHEMA_GENERATOR_URL: http://publisher-avro-schema-generator:8080
  SCHEMA_VALIDATION_URL: http://<ip address> # insert the schema registry public URL or an empty string if schema registry is not deployed
  IMAGE_PULL_SECRET: regcred
  KUBERNETES_NAMESPACE: dataphos
  SECRET_NAME_PUBSUB: pubsub-key
  SECRET_NAME_KAFKA: kafka-tls-credentials
  SECRET_NAME_NATS: nats-tls-credentials
  SECRET_NAME_PULSAR: pulsar-tls-credentials
---

# WebUI
kind: ConfigMap
apiVersion: v1
metadata:
  name: publisher-webui-config
  namespace: dataphos
data:
  "server.properties": |
    window.MANAGER_ENDPOINT = "/backend"
---

apiVersion: v1
kind: Service
metadata:
  name: publisher-postgres
  namespace: dataphos
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
  namespace: dataphos
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
        namespace: dataphos
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 20Gi
---

# Initialize metadata database
apiVersion: batch/v1
kind: Job
metadata:
  name: publisher-initdb
  namespace: dataphos
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
  namespace: dataphos
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
  namespace: dataphos
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

apiVersion: v1
kind: Service
metadata:
  name: publisher-manager
  namespace: dataphos
spec:
  selector:
    app: server
    component: manager
  ports:
    - port: 8080
      targetPort: 8080
  type: ClusterIP
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-manager
  namespace: dataphos
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

apiVersion: v1
kind: Service
metadata:
  name: publisher-data-fetcher
  namespace: dataphos
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
  namespace: dataphos
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
      initContainers:
        - name: check-manager-health
          image: curlimages/curl:7.85.0
          command: ['sh', '-c', 'while [ `curl -s -o /dev/null -w "%{http_code}" http://publisher-manager:8080` -ne 200 ]; do echo waiting for manager to be ready...; sleep 10; done;']
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


# Kubernetes Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: publisher-sa
  namespace: dataphos
---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: publisher-sa-role
  namespace: dataphos
rules:
  - apiGroups: [""] # "" indicates the core API group
    resources: ["pods"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: publisher-sa-rb
  namespace: dataphos
subjects:
  - kind: ServiceAccount
    name: publisher-sa
roleRef:
  kind: Role
  name: publisher-sa-role
  apiGroup: rbac.authorization.k8s.io
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-scheduler
  namespace: dataphos
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

apiVersion: v1
kind: Service
metadata:
  name: publisher-webui
  namespace: dataphos
spec:
  selector:
    app: webui
    component: webui
  ports:
    - port: 8080
  type: NodePort
---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: publisher-webui-ingress
  namespace: dataphos
  annotations:
    kubernetes.io/ingress.global-static-ip-name: <webui-static-IP-name> # insert the name of your static IP address for Web UI ingress
    ingress.gcp.kubernetes.io/pre-shared-cert: <webui-certificate-name> # insert the name of your Google managed certificate
spec:
  rules:
    - host: <webui-domain-name> # insert your webui domain name, same as in the Manager config map
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: publisher-webui
                port:
                  number: 8080
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: publisher-webui
  namespace: dataphos
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
```
{{< /details >}}

## Publisher secrets
{{< details "YAML example" >}}

```
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: dataphos
---

apiVersion: v1
kind: Secret
metadata:
  name: webui-tls-secret
  namespace: dataphos
type: kubernetes.io/tls
stringData:
  tls.crt: <tls.crt>
  tls.key: <tls.key>
```
{{< /details >}}

## v3 config
{{< details "YAML example" >}}

```
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = <country-name>
ST = <state-province-name>
L = <locality-name>
O = <organization-name>
OU = <organization-unit-name>
CN = <common-name>
[v3_req]
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = <domain-name>
DNS.2 = <webui-domain-name>
```
{{< /details >}}

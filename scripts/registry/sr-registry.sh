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
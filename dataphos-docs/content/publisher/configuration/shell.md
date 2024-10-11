---
title: "Shell"
draft: false
weight: 1
---


## Parameters in YAML files needed for any Publisher deployment

|Resource  |Parameter Name  |Description   |Default   |
|---|---|---|---|
|publisher-postgres-secret   |POSTGRES_USER  |Metadata database username   |publisher   |
|publisher-metadata-secret  |METADATA_USERNAME  |Metadata database username   |publisher   |
|publisher-postgres-secret  |POSTGRES_PASSWORD  |Metadata database password  |samplePassworD1212   |
|publisher-metadata-secret  |METADATA_PASSWORD  |Metadata database password   |samplePassworD1212   |   
|publisher-postgres-secret 	|POSTGRES_DB 	| Metadata database name 	| publisher |
|encryption-keys   |.stringData."keys.yaml" |Encryption keys for messages used by Worker component (32 bytes needed)| D2C0B5865AE141A49816F1FDC110FA5A|
|publisher-manager-secret   |JWT_SECRET   |JWT encryption key for secure communication between Manager and WebUI (16 bytes needed)|SuperSecretPass!   | 
|publisher-manager-ingress  |host   |Manager domain name  |  |  
|publisher-webui-config   |data."server.properties".window. MANAGER_ENDPOINT|Manager domain  |  |
|publisher-webui-ingress   |host   | Web UI domain name  |  |  
|publisher-manager-config   |WEB_UI   |Web UI domain   |  |  
|publisher-scheduler-config  |SCHEMA_VALIDATION_URL  |Schema Registry public URL or local Kubernetes service IP address  |  | 

In addition, the YAML file for deployment to GCP (utilizing the native GCP networking resources) requires these four additional parameters.

|Resource Name  |Parameter Name  |Description   |
|---|---|---|  
|publisher-manager-ingress |kubernetes.io/ingress.global-static-ip-name  |Manager ingress static IP address name   |
|publisher-manager-ingress |ingress.gcp.kubernetes.io/pre-shared-cert |Manager Google managed certificate name  | 
|publisher-webui-ingress   |kubernetes.io/ingress.global-static-ip-name   |Web UI ingress static IP address   |  
|publisher-webui-ingress   |ingress.gcp.kubernetes.io/pre-shared-cert   | Web UI Google managed certificate name  |
|pubsub-key 	| "key.json" 	|Base64 encoded PubSub key 	| 

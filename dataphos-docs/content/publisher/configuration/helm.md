---
title: "Helm"
draft: false
weight: 2
---



# Configuration in the dataphos-publisher chart  {#reference_publisher}

Below is the list of configurable options in the `values.yaml` file.

| Variable                   | Type    | Description                                                                                                                                            | Default                                                         |
|----------------------------|---------|--------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| namespace                  | string  | The namespace to deploy the Publisher into.                                                                                                            | `dataphos`                                                      |
| images                     | object  | Docker images to use for each of the individual Publisher sub-components.                                                                              |                                                                 |
| images.initdb              | string  | Initdb Docker image.                                                                                                                                   | `syntioinc/dataphos-publisher-initdb:1.0.0`                    |
| images.avroSchemaGenerator | string  | Avro schema generator image.                                                                                                                           | `syntioinc/dataphos-publisher-avro-schema-generator:1.0.0`     |
| images.scheduler           | string  | Scheduler image.                                                                                                                                       | `syntioinc/dataphos-publisher-scheduler:1.0.0`                 |
| images.manager             | string  | Manager image.                                                                                                                                         | `syntioinc/dataphos-publisher-manager:1.0.0`                   |
| images.fetcher             | string  | Fetcher image.                                                                                                                                         | `syntioinc/dataphos-publisher-data-fetcher:1.0.0`              |
| images.worker              | string  | Worker image.                                                                                                                                          | `syntioinc/dataphos-publisher-worker:1.0.0`                    |
| testMode                   | boolean | Whether some internal services should be exposed if the Publisher is being deployed as part of debugging/testing (for example, the metadata database). | `false`                                                         |
| encryptionKeys             | string  | A multi-line string written in a key-value pair way. Each pair is a separate key that could be used by the Publisher instance when encrypting data.    | `ENC_KEY_1: "D2C0B5865AE141A49816F1FDC110FA5A"`                 |
| manager                    | object  | The Manager configuration object.                                                                                                                      |                                                                 |
| manager.metadataUser       | string  | Metadata database username.                                                                                                                            | `someuser`                                                      |
| manager.metadataPassword   | string  | Metadata database password.                                                                                                                            | `somepassword`                                                  |
| webui                      | object  | Web UI configuration object.                                                                                                                           |                                                                 |
| webui.endpoint             | string  | Web UI endpoint (used by the Manager when performing CORS validation)                                                                                  | `http://localhost:9999`                                         |
| schemaRegistry             | object  | Schema Registry configuration object.                                                                                                                  |                                                                 |
| schemaRegistry.url         | string  | The URL to the Schema Registry (if present)                                                                                                            | `http://schema-registry-svc.<namespace>.svc.cluster.local:8080` |

# Configuration in the dataphos-publisher-webui chart {#reference_publisher_webui}

Below is the list of configurable options in the `values.yaml` file.

| Variable     | Type   | Description                                                               | Default                                     |
|--------------|--------|---------------------------------------------------------------------------|---------------------------------------------|
| namespace    | string | The namespace to deploy the Publisher into.                               | `dataphos`                                  |
| images       | object | Docker images to use for each of the individual Publisher sub-components. |                                             |
| images.webui | string | Web UI image.                                                             | `syntioinc/dataphos-publisher-webui:1.0.0`  |
| webui        | object | Web UI configuration object.                                              |                                             |


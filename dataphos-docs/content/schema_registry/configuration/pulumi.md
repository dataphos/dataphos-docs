---
title: "Pulumi"
draft: false
weight: 3
---

## ⚙️ Configuration

There are three possible sources of resource configuration values: user configuration in the active stack configuration file, retrieved data from existing resources, and default system-level configuration from the application code.

User configuration will always take precedence over other configuration sources. If there is no special user configuration for a parameter, the retrieved value from the resource’s previous configuration will be used. If there wasn’t any data retrieved for the resource (as it is being created for the first time), the default system-level configuration value will be used instead. The default values for parameters are listed in the appropriate section of the configuration options.

If the configuration references an existing cloud resource, the program will retrieve its data from the cloud provider and import the resource into the active stack instead of creating a new one. If the user configuration values specify any additional parameters that differ from the resource configuration while it has not yet been imported into the stack, the deployment will fail. To modify an existing resource’s configuration, import it into the stack first and then redeploy the infrastructure with the desired changes.

**Note:** Implicit import of an AKS cluster is currently not supported. To use an existing AKS cluster in your infrastructure, set the AKS cluster's `import` configuration option to `true`.

⚠️ **WARNING** ⚠️

Imported resources will **NOT** be retained by default when the infrastructure is destroyed. If you want to retain a resource when the infrastructure is destroyed, you need to explicitly set its `retain` flag to `true` in the active stack's configuration file. Retained resources will not be deleted from the backing cloud provider, but will be removed from the Pulumi state on a `pulumi destroy`.
Azure resource groups and GCP projects are set to be retained by default and can be deleted manually. Be careful if you choose not to retain them, as destroying them will remove **ALL** children resources, even the ones created externally. It is recommended to modify these options only if you are using a dedicated empty project/resource group.

### Global configuration options

| Variable                 | Type    | Description                                                                                                    | Default value |
|--------------------------|---------|----------------------------------------------------------------------------------------------------------------|---------------|
| `namespace`              | string  | The name of the Kubernetes namespace where Dataphos Helm charts will be deployed to.                           | `dataphos`    |
| `deploySchemaRegistry`   | boolean | Whether the Schema Registry Helm chart should be deployed.                                                     | `false`       |
| `deploySchemaValidators` | boolean | Whether the Schema Validator Helm chart should be deployed.                                                    | `false`       |
| `retainResourceGroups`   | boolean | Whether Azure resource groups should be retained when the infrastructure is destroyed.                         | `true`        |
| `retainProjects`         | boolean | Whether GCP projects should be retained when the infrastructure is destroyed.                                  | `true`        |
| `resourceTags`           | object  | Set of `key:value` tags attached to all Azure resource groups; or set of labels attached to all GCP resources. |               |

### Product configuration options

The `namespace` and `images` options at the top-level of the Helm chart configurations are set by default and do not need to be manually configured.

Cloud-specific variables should not be manually configured. Depending on the configured cloud provider, service accounts with appropriate roles are automatically created and their credentials are used to populate these variables.

| Variable                              | Type   | Description                                                                                                                                                                                                                                                                      |
|---------------------------------------|--------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `dataphos-schema-registry`            | object | Dataphos Schema Registry Helm chart configuration. Configuration options are listed in the [schema registry configuration]({{< ref "helm#reference_schema_registry">}}).                                   |
| `dataphos-schema-validator`           | object | Dataphos Schema Validator Helm chart configuration. Configuration options are listed in the [schema validator configuration]({{< ref "helm#reference_schema_validator">}}).                                              |
| `dataphos-schema-validator.validator` | object | The object containing the information on all of the validators to be deployed. Configuration options are listed in the [validator configuration]({{< ref "helm#reference_validator">}}). |



## Provider configuration options
The variables listed here are required configuration options by their respective Pulumi providers. Your entire infrastructure should reside on a single cloud platform. Deployment across multiple cloud platforms is currently not fully supported.

{{< tabs "Provider configuration options" >}}

{{< tab "Azure" >}}
| Variable                | Type   | Description                        | Example value |
|-------------------------|--------|------------------------------------|---------------|
| `azure-native:location` | string | The default resource geo-location. | `westeurope`  |

A list of all configuration options for this provider can be found here:
[Azure Native configuration options](https://www.pulumi.com/registry/packages/azure-native/installation-configuration/#configuration-options).

{{</ tab >}}


{{< tab "GCP" >}}
To successfully deploy resources in a GCP project, the appropriate APIs need to be enabled for that project in the API Console. See: [Enable and disable APIs](https://support.google.com/googleapi/answer/6158841).

| Variable      | Type   | Description              | Example value     |
|---------------|--------|--------------------------|-------------------|
| `gcp:project` | string | The default GCP project. | `syntio-dataphos` |
| `gcp:region`  | string | The default region..     | `europe-west2`    |
| `gcp:zone`    | string | The default zone.        | `europe-west2-a`  |

A list of all configuration options for this provider can be found here:
[GCP configuration options](https://www.pulumi.com/registry/packages/gcp/installation-configuration/#configuration-reference).

{{</ tab >}}
{{</ tabs >}}

## Cluster configuration options

The stack configuration `cluster` object is utilized to configure the Kubernetes cluster necessary to deploy the Helm charts that comprise Dataphos products.

### Common cluster configuration

| Variable                    | Type    | Description                                                                                                                                                                                    |
|-----------------------------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `cluster`                   | object  | The object containing the general information on the cluster.                                                                                                                                  |
| `cluster.CLUSTER_ID`        | object  | The object representing an individual cluster's configuration.                                                                                                                                 |
| `cluster.CLUSTER_ID.type`   | string  | The type of the managed cluster. Valid values: [`gke`, `aks`].                                                                                                                                 |
| `cluster.CLUSTER_ID.name`   | string  | The name of the managed cluster.                                                                                                                                                               |
| `cluster.CLUSTER_ID.retain` | boolean | If set to true, resource will be retained when infrastructure is destroyed. Retained resources will not be deleted from the backing cloud provider, but will be removed from the Pulumi state. |

### Specific cluster configuration

{{< tabs "Cluster configuration options" >}}

{{< tab "AKS" >}}
| Variable                                                 | Type    | Description                                                                                                                                                                                  | Default value     |
|----------------------------------------------------------|---------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------|
| `cluster.CLUSTER_ID.import`                              | boolean | Whether to use an existing AKS cluster instead of creating a new one.<br>**Note:** AKS clusters imported in this way will be retained on destroy, unless its resource group is not retained. | `false`           |
| `cluster.CLUSTER_ID.resourceGroup`                       | string  | The name of the resource group. The name is case insensitive.                                                                                                                                |                   |
| `cluster.CLUSTER_ID.sku`                                 | object  | The managed cluster SKU.                                                                                                                                                                     |                   |
| `cluster.CLUSTER_ID.sku.name`                            | string  | The managed cluster SKU name.                                                                                                                                                                | `Basic`           |
| `cluster.CLUSTER_ID.sku.tier`                            | string  | The managed cluster SKU tier.                                                                                                                                                                | `Free`            |
| `cluster.CLUSTER_ID.dnsPrefix`                           | string  | The cluster DNS prefix. This cannot be updated once the Managed Cluster has been created.                                                                                                    |                   |
| `cluster.CLUSTER_ID.agentPoolProfiles`                   | object  | The agent pool properties.                                                                                                                                                                   |                   |
| `cluster.CLUSTER_ID.agentPoolProfiles.name`              | string  | Windows agent pool names must be 6 characters or less.                                                                                                                                       |                   |
| `cluster.CLUSTER_ID.agentPoolProfiles.count`             | integer | Number of agents (VMs) to host docker containers.                                                                                                                                            | `3`               |
| `cluster.CLUSTER_ID.agentPoolProfiles.enableAutoScaling` | boolean | Whether to enable auto-scaler.                                                                                                                                                               | `false`           |
| `cluster.CLUSTER_ID.agentPoolProfiles.minCount`          | integer | The minimum number of nodes for auto-scaling.                                                                                                                                                | `1`               |
| `cluster.CLUSTER_ID.agentPoolProfiles.maxCount`          | integer | The maximum number of nodes for auto-scaling.                                                                                                                                                | `5`               |
| `cluster.CLUSTER_ID.agentPoolProfiles.vmSize`            | string  | VM size availability varies by region. See: [Supported VM sizes](https://docs.microsoft.com/azure/aks/quotas-skus-regions#supported-vm-sizes)                                                | `Standard_DS2_v2` |
| `cluster.CLUSTER_ID.tags`                                | object  | Set of `key:value` tags attached to the AKS Cluster. This will override the global `resourceTags` configuration option for this resource.                                                    |                   |


{{</ tab >}}

{{< tab "GKE" >}}

| Variable                                                       | Type        | Description                                                                                                                                                                                                        | Default value                                                                                                                                                                                                      |
|----------------------------------------------------------------|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `cluster.CLUSTER_ID.projectID`                                 | string      | The project ID is a unique identifier for a GCP project.                                                                                                                                                           |                                                                                                                                                                                                                    |
| `cluster.CLUSTER_ID.location`                                  | string      | The geo-location where the resource lives.                                                                                                                                                                         |                                                                                                                                                                                                                    |
| `cluster.CLUSTER_ID.initialNodeCount`                          | integer     | The number of nodes to create in this cluster's default node pool.                                                                                                                                                 | `3`                                                                                                                                                                                                                |
| `cluster.CLUSTER_ID.nodeConfigs`                               | object      | Parameters used in creating the default node pool.                                                                                                                                                                 |                                                                                                                                                                                                                    |
| `cluster.CLUSTER_ID.nodeConfig.machineType`                    | string      | The name of a Google Compute Engine machine type.                                                                                                                                                                  | `e2-medium`                                                                                                                                                                                                        |
| `cluster.CLUSTER_ID.clusterAutoscalings`                       | object list | Per-cluster configuration of Node Auto-Provisioning with Cluster Autoscaler to automatically adjust the size of the cluster and create/delete node pools based on the current needs of the cluster's workload.     |                                                                                                                                                                                                                    |
| `cluster.CLUSTER_ID.clusterAutoscalings[0].autoscalingProfile` | string      | Lets you choose whether the cluster autoscaler should optimize for resource utilization or resource availability when deciding to remove nodes from a cluster. Valid values: [`BALANCED`, `OPTIMIZE_UTILIZATION`]. | `BALANCED`                                                                                                                                                                                                         |
| `cluster.CLUSTER_ID.clusterAutoscalings[0].enabled`            | boolean     | Whether node auto-provisioning is enabled.                                                                                                                                                                         | `false`                                                                                                                                                                                                            |
| `cluster.CLUSTER_ID.clusterAutoscalings[0].resourceLimits`     | object list | Global constraints for machine resources in the cluster. Configuring the cpu and memory types is required if node auto-provisioning is enabled.                                                                    | resourceLimits:<br>-&nbsp;resource_type:&nbsp;cpu<br>&nbsp;&nbsp;minimum:&nbsp;1<br>&nbsp;&nbsp;maximum:&nbsp;1<br>-&nbsp;resource_type:&nbsp;memory<br>&nbsp;&nbsp;minimum:&nbsp;1<br>&nbsp;&nbsp;maximum:&nbsp;1 |
| `cluster.CLUSTER_ID.resourceLabels`                            | object      | Set of `key:value` labels attached to the GKE Cluster. This will override the global `resourceTags` configuration option for this resource.                                                                        |                                                                                                                                                                                                                    |

{{</ tab >}}
{{</ tabs >}}

## Broker configuration options
The stack configuration `brokers` object is used to set up the key references to be used by the dataphos components to connect to one or more brokers deemed to be part of the overall platform infrastructure.

Product configs directly reference brokers by their `BROKER_ID` listed in the broker config. The same applies to `TOPIC_ID` and `SUB_ID` – the keys of those objects are the actual names of the topics and subscriptions used.

### Common broker configuration

| Variable                                                                 | Type    | Description                                                                                                                                                                                    |
|--------------------------------------------------------------------------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `brokers`                                                                | object  | The object containing the general information on the brokers.                                                                                                                                  |
| `brokers.BROKER_ID`                                                      | object  | The object representing an individual broker's configuration.                                                                                                                                  |
| `brokers.BROKER_ID.type`                                                 | string  | Denotes the broker's type. Valid values: [`kafka`, `pubsub`, `servicebus`].                                                                                                                    |
| `brokers.BROKER_ID.topics`                                               | object  | The object containing the general information on the topics.                                                                                                                                   |
| `brokers.BROKER_ID.topics.TOPIC_ID`                                      | object  | The object representing an individual topic's configuration.                                                                                                                                   |
| `brokers.BROKER_ID.topics.TOPIC_ID.retain`                               | boolean | If set to true, resource will be retained when infrastructure is destroyed. Retained resources will not be deleted from the backing cloud provider, but will be removed from the Pulumi state. |
| `brokers.BROKER_ID.topics.TOPIC_ID.subscriptions`                        | object  | The object containing topic subscription (consumer group) configuration.                                                                                                                       |
| `brokers.BROKER_ID.topics.TOPIC_ID.subscriptions.SUBSCRIPTION_ID`        | object  | The object representing an individual topic subscription's configuration.                                                                                                                      |
| `brokers.BROKER_ID.topics.TOPIC_ID.subscriptions.SUBSCRIPTION_ID.retain` | boolean | If set to true, resource will be retained when infrastructure is destroyed. Retained resources will not be deleted from the backing cloud provider, but will be removed from the Pulumi state. |

The Azure storage account type. Valid values: [`Storage`, `StorageV2`, `BlobStorage`, `BlockBlobStorage`, `FileStorage`]. The default and recommended value is `BlockBlobStorage`.

### Specific broker configuration

{{< tabs Broker configuration options >}}
{{< tab "Azure Service Bus" >}}
| Variable                          | Type    | Description                                                                                                                                                                                                           |
|-----------------------------------|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `brokers.BROKER_ID.azsbNamespace` | string  | The Azure Service Bus namespace name.                                                                                                                                                                                 |
| `brokers.BROKER_ID.resourceGroup` | string  | The Azure Service Bus resource group name.                                                                                                                                                                            |
| `brokers.BROKER_ID.sku`           | object  | The Azure Service Bus namespace SKU properties.                                                                                                                                                                       |
| `brokers.BROKER_ID.sku.name`      | string  | Name of this SKU. Valid values: [`BASIC`, `STANDARD`, `PREMIUM`]. Default value is `STANDARD`.                                                                                                                        |
| `brokers.BROKER_ID.sku.tier`      | string  | The billing tier of this SKU. [`BASIC`, `STANDARD`, `PREMIUM`]. Default value is `STANDARD`.                                                                                                                          |
| `brokers.BROKER_ID.sku.capacity`  | integer | The specified messaging units for the tier. For Premium tier, valid capacities are 1, 2 and 4.                                                                                                                        |
| `brokers.BROKER_ID.tags`          | object  | Set of `key:value` tags attached to the Azure Service Bus namespace. This will override the global `resourceTags` configuration option for this resource.                                                             |
| `brokers.BROKER_ID.retain`        | boolean | If set to true, the Azure Service Bus namespace will be retained when infrastructure is destroyed. Retained resources will not be deleted from the backing cloud provider, but will be removed from the Pulumi state. |

{{</ tab >}}


{{< tab "Google Cloud Pub/Sub" >}}
| Variable                                                                 | Type   | Description                                                                                                                                          |
|--------------------------------------------------------------------------|--------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `brokers.BROKER_ID.projectID`                                            | string | The GCP project ID.                                                                                                                                  |
| `brokers.BROKER_ID.topics.TOPIC_ID.labels`                               | object | Set of `key:value` labels attached to the Pub/Sub topic. This will override the global `resourceTags` configuration option for this resource.        |
| `brokers.BROKER_ID.topics.TOPIC_ID.subscriptions.SUBSCRIPTION_ID.labels` | object | Set of `key:value` labels attached to the Pub/Sub subscription. This will override the global `resourceTags` configuration option for this resource. |

{{</ tab >}}

{{< tab "Kafka" >}}
| Variable                                       | Type    | Description                                                                                                                                                 | Default value   |
|------------------------------------------------|---------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|
| `brokers.BROKER_ID.brokerAddr`                 | string  | The Kafka bootstrap server address. Optional. If omitted or empty, a new Strimzi Kafka cluster operator and cluster will be deployed with default settings. |                 |
| `brokers.BROKER_ID.clusterName`                | string  | The name of the Strimzi Kafka cluster custom Kubernetes resource.                                                                                           | `kafka-cluster` |
| `brokers.BROKER_ID.clusterNamespace`           | string  | The Kubernetes namespace where the cluster will be deployed.                                                                                                | `kafka-cluster` |
| `brokers.BROKER_ID.topics.TOPIC_ID.partitions` | integer | Number of partitions for a specific topic.                                                                                                                  | `3`             |
| `brokers.BROKER_ID.topics.TOPIC_ID.replicas`   | integer | Number of replicas for a specific topic.                                                                                                                    | `1`             |

{{</ tab >}}
{{</ tabs >}}


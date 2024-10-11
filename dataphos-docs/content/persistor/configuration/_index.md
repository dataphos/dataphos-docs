---
title: "Deployment Customization"
draft: false
weight: 4
geekdocCollapseSection: true
---

This page describes Persistor architecture. Whereas the [Quickstart](/persistor/quickstart) will get you started fairly quickly, this page will explain more precisely the individual components being deployed, how they interact and how to configure them. The following pages go into further detail on how to customize your Kubernetes deployments:
{{< toc-tree >}}


# Persistor Architecture

The following diagram gives an overview of the individual Persistor components and how they interact with your underlying Kubernetes environment:

![Architecture](/persistor_arch.png)

When deploying the Persistor, you deploy the following components:

* The **Persistor Core** component, responsible for attaching itself to the streaming service and persisting the data to blob storage.
* The **Indexer Database** that will be used to track where messages are located across your Data Lake.
* The **Indexer** component, responsible for storing the metadata in the Indexer Database.
* The **Indexer API**, responsible for querying the **Indexer Database**.
* The **Resubmitter**, responsible for resubmitting the messages by querying the Indexer Database, retrieving the data based on the found locations and resubmitting it to the target broker.


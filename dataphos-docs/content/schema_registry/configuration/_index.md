---
title: "Deployment Customization"
draft: false
weight: 4
geekdocCollapseSection: true
---


This page describes the Schema Registry architecture. Whereas [Quickstart](/schema_registry/quickstart) will get you started fairly quickly, this page will explain more precisely the individual components being deployed, how they interact and how to configure them. The following pages go into further detail on how to customize your Kubernetes deployments:
{{< toc-tree >}}

# Schema Registry Architecture

The following diagram gives an overview of the individual Schema Registry components and how they interact with your underlying Kubernetes environment:

![Architecture](/sr_architecture.png)

When deploying the Schema Registry, you deploy the following components:

* The **Postgres History Database** that will be used to store the schemas submitted to the Schema Registry.
* The **Schema Registry** REST server is used by users and validators to submit and pull schemas respectively.
* The **Schema Compatibility Checker** is a utility used by the Schema Registry server to ensure new schemas follow the designated compatibility mode.
* The **Schema Validity Checker** is a utility used by the Schema Registry server to ensure new schemas are valid to begin with.
* The **Validator** component is the specific component you attach to a message broker topic for validation purposes.
* **(Optionally used if validating XML data)** The **XML Validator** is a utility, decoupled validator used for validating XML schemas.
* **(Optionally used if validating CSV data)** The **CSV Validator** is a utility, decoupled validator used for validating CSV schemas.

---
title: "Persistor"
draft: false
weight: 1
---

The Persistor is a stateless component designed to store messages procured from a topic within a data pipeline, providing a seamless interface for their retrieval and potential resubmission to a topic. Acting as a failsafe, Persistor establishes a connection to a message broker through a subscription, methodically archiving messages either individually or in batches.

{{< toc-tree >}}

# PTFE resource provisioner and software installer - GCP

Provisions the necessary GCP resources for each PTFE installation type.

Each installation type is separated into a module with a common network module all can share.

## Installation types

Under development:

- __pes__ - Production (External Services) - two VM instances in separate zones with provision of PostgreSQL and Cloud Storage bucket for data storage

Future work:

- __demo__ - Proof of Concept - single VM instance with enough disk space for data storage
- __pmd__ - Production (Mounted Disk) - single VM instance with attached EBS volume for data storage

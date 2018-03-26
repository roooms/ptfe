# Replicated PTFE Installer

Automates the provision of the necessary AWS infrastructure for each PTFE installation type.

Each installation type is separated out into a module with a common network module all can share.

* __demo__ - single EC2 instance with enough disk space for data storage
* __pmd__ - single EC2 instance with attached EBS volume for data storage
* __pes__ - two EC2 instances in separate AZs with provision of PostgreSQL RDS and S3 bucket for data storage

Must be run in the HashiCorp SE AWS account to access the hashidemos.io hosted zone.

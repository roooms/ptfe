# PTFE resource provisioner and software installer - AWS

Provisions the necessary AWS resources for each PTFE installation type and then performs an automated install of PTFE.

Each installation type is separated into a module with a common network module all can share.

## Installation types

Working:

- __demo__ - Proof of Concept - single EC2 instance with enough disk space for data storage

Under development:

- __pmd__ - Production (Mounted Disk) - single EC2 instance with attached EBS volume for data storage
- __pes__ - Production (External Services) - two EC2 instances in separate AZs with provision of PostgreSQL RDS and S3 bucket for data storage

## Requirements

- Existing hosted zone configured in Route53
- Existing SSH key pair installed in the chosen AWS region

## Limitations

- Provisioners currently hardcoded to use the `ubuntu` SSH user so an Ubuntu AMI is required

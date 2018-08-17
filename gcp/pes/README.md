# PTFE (External Services) resource provisioner - GCP

Provisions the necessary GCP resources for the External Services installation type.

## Resources

* google_compute_instance.ptfe1
* google_compute_instance.ptfe2
* google_sql_database_instance.pes
* google_storage_bucket.pes

## Architecture

### Application Layer

The `network` module uses a data source to discover healthy availability zones and returns them as a list:

```hcl
data "google_compute_zones" "main" {
  status = "UP"
}
```

The resulting list is passed into the `pes` module as the `zone` variable. The first two availability zones in the list are used as locations for two VM instances (**ptfe1** and **ptfe2**) ensuring they are in different availability zones:

```hcl
resource "google_compute_instance" "ptfe1" {
  zone = "${var.zone[0]}"
}

resource "google_compute_instance" "ptfe2" {
  zone = "${var.zone[1]}"
}
```

Conditional logic is used to assign an active alias IP to the active VM instance, which is defined by a Terraform variable:

```hcl
variable "active_ptfe_instance" {
  description = "The active PTFE instance ie ptfe1 or ptfe2"
  default     = "ptfe1"
}

variable "active_alias_ip" {
  description = "Alias IP attached to the active PTFE VM instance"
}

variable "standby_alias_ip" {
  description = "Alias IP attached to the standby PTFE VM instance"
}

resource "google_compute_instance" "ptfe1" {
  network_interface {
    alias_ip_range = {
      ip_cidr_range = "${var.active_ptfe_instance == "ptfe1" ? var.active_alias_ip : var.standby_alias_ip}/32"
    }
  }
}

resource "google_compute_instance" "ptfe2" {
  network_interface {
    alias_ip_range = {
      ip_cidr_range = "${var.active_ptfe_instance == "ptfe2" ? var.active_alias_ip : var.standby_alias_ip}/32"
    }
  }
}
```

Using the above conditional logic, the `active_alias_ip` can be switched between `ptfe1` and `ptfe2` by changing the value of `active_ptfe_instance` and performing a Terraform run. This could be done manually or automatically following an availability zone failure. Note that the Terraform run would likely produce an error as it will fail to update the configuration of the compute VM instance in the failed availability zone, but the change to the available compute VM instance would succeed.

### Storage Layer

Google Cloud SQL (PostgreSQL) and Google Cloud Storage are configured with `REGIONAL` availability and resiliency, resulting in both services remaining available in the event of an availability zone failure. The Google Cloud Platform documentation provides more information on the exact behaviour of each service during an availability zone failure.

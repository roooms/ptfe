#------------------------------------------------------------------------------
# production external-services ptfe resources
#------------------------------------------------------------------------------

locals {
  namespace = "${var.namespace}-pes"
}

resource "google_compute_instance" "ptfe1" {
  name         = "${local.namespace}-instance-ptfe1"
  machine_type = "${var.gcp_machine_type}"
  zone         = "${var.zone[0]}"

  boot_disk {
    initialize_params {
      size  = 50
      image = "${var.gcp_machine_image}"
    }
  }

  network_interface {
    subnetwork = "${var.subnetwork}"

    alias_ip_range = {
      ip_cidr_range = "${var.active_ptfe_instance == "ptfe1" ? var.active_alias_ip : var.standby_alias_ip}/32"
    }
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/sqlservice.admin"]
  }

  allow_stopping_for_update = true
}

resource "google_compute_instance" "ptfe2" {
  name         = "${local.namespace}-instance-ptfe2"
  machine_type = "${var.gcp_machine_type}"
  zone         = "${var.zone[1]}"

  boot_disk {
    initialize_params {
      size  = 50
      image = "${var.gcp_machine_image}"
    }
  }

  network_interface {
    subnetwork = "${var.subnetwork}"

    alias_ip_range = {
      ip_cidr_range = "${var.active_ptfe_instance == "ptfe2" ? var.active_alias_ip : var.standby_alias_ip}/32"
    }
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/sqlservice.admin"]
  }

  allow_stopping_for_update = true
}

resource "google_sql_database_instance" "pes" {
  #name = "${local.namespace}-sql-db" # cannot be reused for one week
  database_version = "POSTGRES_9_6"
  region           = "${var.region}"

  settings {
    availability_type = "REGIONAL"
    tier              = "db-custom-4-16384"
    disk_size         = "50"

    location_preference {
      zone = "${var.zone[0]}"
    }
  }
}

resource "google_storage_bucket" "pes" {
  name          = "${local.namespace}-storage-bucket"
  location      = "${var.region}"
  storage_class = "REGIONAL"
  force_destroy = true
}

#------------------------------------------------------------------------------
# bastion host resources
#------------------------------------------------------------------------------

locals {
  namespace = "${var.namespace}"
}

resource "google_compute_instance" "bastion" {
  name         = "${local.namespace}-instance-bastion"
  machine_type = "${var.gcp_machine_type}"
  zone         = "${var.zone[0]}"

  boot_disk {
    initialize_params {
      size  = 10
      image = "${var.gcp_machine_image}"
    }
  }

  network_interface {
    access_config = {}
    subnetwork    = "${var.subnetwork}"
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/sqlservice.admin"]
  }

  allow_stopping_for_update = true
}

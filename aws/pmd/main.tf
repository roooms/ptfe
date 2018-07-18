#------------------------------------------------------------------------------
# production mounted disk ptfe resources
#------------------------------------------------------------------------------

locals {
  namespace = "${var.namespace}-pmd"
  hostname  = "${local.namespace}.${var.route53_zone}"
}

resource "aws_instance" "pmd" {
  count                  = 2
  ami                    = "${var.aws_instance_ami}"
  instance_type          = "${var.aws_instance_type}"
  subnet_id              = "${element(var.subnet_ids, count.index)}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  key_name               = "${var.ssh_key_name}"

  provisioner "file" {
    source      = "${var.license_path}"
    destination = "/tmp/license.rli"

    connection {
      user        = "ubuntu"
      private_key = "${file("${var.ssh_key_path}")}"
    }
  }

  provisioner "file" {
    source      = "${var.tls_cert_path}"
    destination = "/tmp/fullchain.pem"

    connection {
      user        = "ubuntu"
      private_key = "${file("${var.ssh_key_path}")}"
    }
  }

  provisioner "file" {
    source      = "${var.tls_key_path}"
    destination = "/tmp/private.key"

    connection {
      user        = "ubuntu"
      private_key = "${file("${var.ssh_key_path}")}"
    }
  }

  provisioner "file" {
    content     = "${data.template_file.replicated_conf.rendered}"
    destination = "/tmp/replicated.conf"

    connection {
      user        = "ubuntu"
      private_key = "${file("${var.ssh_key_path}")}"
    }
  }

  provisioner "file" {
    content     = "${data.template_file.replicated_settings.rendered}"
    destination = "/tmp/replicated-settings.json"

    connection {
      user        = "ubuntu"
      private_key = "${file("${var.ssh_key_path}")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/fullchain.pem /etc/",
      "sudo mv /tmp/private.key /etc/",

      #      "sudo mv /tmp/replicated.conf /etc/",
      "curl -o install.sh https://install.terraform.io/ptfe/stable",
    ]

    #      "sudo bash install.sh no-proxy",

    connection {
      user        = "ubuntu"
      private_key = "${file("${var.ssh_key_path}")}"
    }
  }

  root_block_device {
    volume_size = 80
    volume_type = "gp2"
  }

  tags {
    Name  = "${local.namespace}-instance-${count.index+1}"
    owner = "${var.owner}"
    TTL   = "${var.ttl}"
  }
}

resource "aws_route53_record" "pmd" {
  zone_id = "${var.route53_zone_id}"
  name    = "${local.hostname}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.pmd.public_ip}"]
}

resource "aws_ebs_volume" "pmd" {
  availability_zone = "${aws_instance.pmd.availability_zone}"
  size              = 88
  type              = "gp2"

  tags {
    Name = "${local.namespace}-ebs_volume"
  }
}

resource "aws_volume_attachment" "pmd" {
  device_name = "/dev/xvdb"
  instance_id = "${aws_instance.pmd.id}"
  volume_id   = "${aws_ebs_volume.pmd.id}"
}

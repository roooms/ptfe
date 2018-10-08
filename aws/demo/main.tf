#------------------------------------------------------------------------------
# demo/poc ptfe resources
#------------------------------------------------------------------------------

locals {
  namespace = "${var.namespace}-demo"
  hostname  = "${local.namespace}.${var.route53_zone}"
}

resource "aws_route53_record" "demo" {
  zone_id = "${var.route53_zone_id}"
  name    = "${local.hostname}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.demo.public_ip}"]
}

data "template_file" "replicated_settings" {
  template = "${file("${path.module}/replicated-settings.tpl.json")}"

  vars {
    hostname = "${local.hostname}"
  }
}

data "template_file" "replicated_conf" {
  template = "${file("${path.module}/replicated.tpl.conf")}"

  vars {
    hostname = "${local.hostname}"
  }
}

resource "aws_instance" "demo" {
  ami                    = "${var.aws_instance_ami}"
  instance_type          = "${var.aws_instance_type}"
  subnet_id              = "${var.subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.demo.id}"]
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
      "sudo mkdir -p /etc/ssl",
      "sudo mv -v /tmp/fullchain.pem /etc/ssl/",
      "sudo mv -v /tmp/private.key /etc/ssl/",
      "sudo mv -v /tmp/replicated.conf /etc/",
      "curl -o install.sh https://install.terraform.io/ptfe/stable",
      "sudo bash install.sh no-proxy",
    ]

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
    Name  = "${local.namespace}-instance"
    owner = "${var.owner}"
    TTL   = "${var.ttl}"
  }
}

#------------------------------------------------------------------------------
# security groups
#------------------------------------------------------------------------------

resource "aws_security_group" "demo" {
  name        = "${local.namespace}-sg"
  description = "${local.namespace} security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8800
    to_port     = 8800
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

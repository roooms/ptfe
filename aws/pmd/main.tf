#------------------------------------------------------------------------------
# production mounted disk ptfe resources
#------------------------------------------------------------------------------

locals {
  namespace = "${var.namespace}-pmd"
  hostname  = "${local.namespace}.${var.route53_zone}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_route53_record" "pmd" {
  zone_id = "${var.route53_zone_id}"
  name    = "${local.hostname}"
  type    = "A"

  alias {
    name                   = "${aws_elb.pmd.dns_name}"
    zone_id                = "${aws_elb.pmd.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_elb" "pmd" {
  name            = "${local.namespace}-elb"
  security_groups = ["${aws_security_group.elb.id}"]
  subnets         = ["${var.subnet_ids}"]
  instances       = ["${aws_instance.pmd.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 15
  }

  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
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

resource "aws_instance" "pmd" {
  count                  = 2
  ami                    = "${var.aws_instance_ami}"
  instance_type          = "${var.aws_instance_type}"
  subnet_id              = "${element(var.subnet_ids, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
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
      "#sudo mkfs -t ext4 /dev/xvdb",
      "sudo mkdir -p /data",
      "#sudo mount /dev/xvdb /data",
      "sudo mkdir -p /etc/ssl",
      "sudo mv /tmp/fullchain.pem /etc/ssl/",
      "sudo mv /tmp/private.key /etc/ssl/",
      "sudo mv /tmp/replicated.conf /etc/",
      "curl -o install.sh https://install.terraform.io/ptfe/stable",
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
    Name  = "${local.namespace}-instance-${count.index+1}"
    owner = "${var.owner}"
    TTL   = "${var.ttl}"
  }
}

resource "aws_ebs_volume" "pmd" {
  availability_zone = "${aws_instance.pmd.0.availability_zone}"
  size              = 88
  type              = "gp2"

  tags {
    Name = "${local.namespace}-ebs_volume"
  }
}

resource "aws_volume_attachment" "pmd" {
  device_name = "/dev/xvdb"
  instance_id = "${aws_instance.pmd.0.id}"
  volume_id   = "${aws_ebs_volume.pmd.id}"
}

#------------------------------------------------------------------------------
# security groups
#------------------------------------------------------------------------------

resource "aws_security_group" "elb" {
  name        = "${local.namespace}-elb-sg"
  description = "${local.namespace} elb security group"
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

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance" {
  name        = "${local.namespace}-instance-sg"
  description = "${local.namespace} instance security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = ["${aws_security_group.elb.id}"]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = ["${aws_security_group.elb.id}"]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 8800
    to_port         = 8800
    security_groups = ["${aws_security_group.elb.id}"]
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

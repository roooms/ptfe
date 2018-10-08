#------------------------------------------------------------------------------
# production external-services ptfe resources
#------------------------------------------------------------------------------

locals {
  namespace = "${var.namespace}-pes"
  hostname  = "${local.namespace}.${var.route53_zone}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_route53_record" "pes" {
  zone_id = "${var.route53_zone_id}"
  name    = "${local.hostname}"
  type    = "A"

  alias {
    name                   = "${aws_elb.pes.dns_name}"
    zone_id                = "${aws_elb.pes.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_elb" "pes" {
  name            = "${local.namespace}-elb"
  security_groups = ["${aws_security_group.elb.id}"]
  subnets         = ["${var.subnet_ids}"]

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

data "template_file" "pes" {
  template = "${file("${path.module}/user-data.tpl")}"

  vars = {
    agent_type = "client"
  }
}

resource "aws_launch_configuration" "pes" {
  associate_public_ip_address = false
  ebs_optimized               = false
  iam_instance_profile        = "${aws_iam_instance_profile.ptfe.name}"
  image_id                    = "${var.aws_instance_ami}"
  instance_type               = "${var.aws_instance_type}"
  user_data                   = "${data.template_file.pes.rendered}"
  key_name                    = "${var.ssh_key_name}"

  security_groups = ["${aws_security_group.asg.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "pes" {
  launch_configuration = "${aws_launch_configuration.pes.id}"
  load_balancers       = ["${aws_elb.pes.id}"]
  vpc_zone_identifier  = ["${var.subnet_ids}"]
  name                 = "${local.namespace}-asg"
  max_size             = "1"
  min_size             = "1"
  desired_capacity     = "1"
  default_cooldown     = 30

  tag {
    key                 = "Name"
    value               = "${local.namespace}-instance"
    propagate_at_launch = true
  }
}

resource "aws_s3_bucket" "pes" {
  bucket = "${local.namespace}-s3-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags {
    Name = "${local.namespace}-s3-bucket"
  }
}

resource "aws_db_instance" "pes" {
  allocated_storage         = 10
  engine                    = "postgres"
  engine_version            = "9.4"
  instance_class            = "db.t2.medium"
  identifier                = "${local.namespace}-db-instance"
  name                      = "ptfe"
  storage_type              = "gp2"
  username                  = "ptfe"
  password                  = "${var.database_pwd}"
  db_subnet_group_name      = "${var.db_subnet_group_name}"
  vpc_security_group_ids    = ["${aws_security_group.asg.id}"]
  final_snapshot_identifier = "${local.namespace}-db-instance-final-snapshot"
}

#------------------------------------------------------------------------------
# iam for ec2 to s3
#------------------------------------------------------------------------------

resource "aws_iam_role" "ptfe" {
  name = "${local.namespace}-iam_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ptfe" {
  name = "${local.namespace}-iam_instance_profile"
  role = "${aws_iam_role.ptfe.name}"
}

data "aws_iam_policy_document" "ptfe" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.pes.id}",
      "arn:aws:s3:::${aws_s3_bucket.pes.id}/*",
    ]

    actions = [
      "s3:*",
    ]
  }
}

resource "aws_iam_role_policy" "ptfe" {
  name   = "${local.namespace}-iam_role_policy"
  role   = "${aws_iam_role.ptfe.name}"
  policy = "${data.aws_iam_policy_document.ptfe.json}"
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

resource "aws_security_group" "asg" {
  name        = "${local.namespace}-asg-sg"
  description = "${local.namespace} asg security group"
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

resource "aws_security_group" "db" {
  name        = "${local.namespace}-db-sg"
  description = "${local.namespace} db security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    protocol        = -1
    from_port       = 0
    to_port         = 0
    security_groups = ["${aws_security_group.asg.id}"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

#------------------------------------------------------------------------------
# vpc / subnets / route tables / igw
#------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "${var.namespace}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.namespace}-internet_gateway"
  }
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "${var.namespace}-route_table"
  }
}

resource "aws_subnet" "public" {
  count             = 3
  cidr_block        = "10.0.${count.index+1}.0/24"
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags {
    Name = "${var.namespace}-public-${element(data.aws_availability_zones.available.names, count.index+1)}"
  }

  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = 3
  cidr_block        = "10.0.1${count.index+1}.0/24"
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags {
    Name = "${var.namespace}-private-${element(data.aws_availability_zones.available.names, count.index+1)}"
  }

  map_public_ip_on_launch = false
}

resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.namespace}"
  description = "${var.namespace}-db_subnet_group"
  subnet_ids  = ["${aws_subnet.public.*.id}"]
}

resource "aws_route_table_association" "main" {
  count          = 2
  route_table_id = "${aws_route_table.main.id}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
}

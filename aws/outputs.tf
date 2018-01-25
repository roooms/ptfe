output "public_ip" {
  value = "${aws_instance.demo.public_ip}"
}

output "public_dns" {
  value = "${aws_instance.demo.public_dns}"
}

output "fqdn" {
  value = "${aws_route53_record.demo.fqdn}"
}

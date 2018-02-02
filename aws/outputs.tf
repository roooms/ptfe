output "replicated console password" {
  value = "${random_pet.replicated-pwd.id}"
}

output "next steps" {
  value = "To finish the installation visit https://${aws_route53_record.demo.fqdn}:8800 to install your license file, choose the release channel and installation type."
}

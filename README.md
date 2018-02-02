# Replicated PTFE Installer

Automates the provision of the necessary AWS infrastructure for a PTFE _demo_ installation.

Must be run in the HashiCorp SE AWS account to access the hashidemos.io hosted zone.

Configures Replicated to the point of requiring a valid license to be installed.

Final interactive steps are:

- Open the Replicated URL `(https://<fqdn>:8800)`
- Enter the generated password for the console
- Upload your license file
- Choose the release channel
- In the PTFE settings page choose `demo` as the install type
- Open the PTFE URL `(https://<fqdn>)`

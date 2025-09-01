# Allow Terraform to read all KV secrets under 'secret/data/terraform/'
path "secret/data/terraform/*" {
  capabilities = ["read", "list"]
}

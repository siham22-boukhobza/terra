# Allow Terraform to read all KV secrets under 'secret/data/terraform/'
path "secret/data/ec2-tag/*" {
  capabilities = ["read", "list"]
}
 
path "auth/token/create" {
capabilities = ["create", "read", "update", "list"]
}
This project demonstrates how to integrate Terraform with HashiCorp Vault using AppRole authentication. It provisions AWS infrastructure and retrieves secrets from Vault’s KV v2 engine securely.

🚀 Features

Deploys an EC2 instance on AWS using Terraform.
Configures Security Groups for SSH and Vault access.

Generates and saves an SSH key pair using Terraform.

Stores secrets (e.g., passwords, bucket names) in Vault KV v2.

Uses Vault AppRole authentication (role_id & secret_id).

Terraform retrieves secrets dynamically from Vault and injects them into AWS resources.

🏗️ Architecture

Vault is running and configured with:

KV v2 secrets engine (secret/).

Policy granting read access to secret/data/ec2-tag.

AppRole auth method with role_id and secret_id.

Terraform:

Authenticates to Vault via AppRole.

Reads secrets from Vault.

Provisions AWS resources (EC2 + Security Groups).

Passes Vault-managed secrets as tags or configuration values.

📂 Project Structure
.
├── main.tf          # Main Terraform configuration
├── variables.tf     # Input variables (AWS region, AMI, instance type, etc.)
├── output.tf        # Outputs (e.g., instance IP, secret values)
├── terraform-policy.hcl # Vault policy definition
├── web.pem          # Private key (generated locally by Terraform)
└── README.md        # Project documentation

⚙️ Prerequisites

Terraform>= 1.5
Vault>= 1.13
AWS account with proper credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
Vault server initialized & unsealed
🔑 Vault Setup

Enable KV v2:

vault secrets enable -path=secret kv-v2
Create a policy (terraform-policy.hcl):
path "secret/data/ec2-tag" {
  capabilities = ["read", "list"]
}
Apply policy:
vault policy write terraform-policy terraform-policy.hcl


Enable AppRole and bind to policy:
vault auth enable approle

vault write auth/approle/role/terraform-role \
  secret_id_ttl=1h \
  token_num_uses=10 \
  token_ttl=1h \
  token_max_ttl=4h \
  policies=terraform-policy

  Fetch role_id:
  vault read auth/approle/role/terraform-role/role-id

Generate secret_id:
vault write -f auth/approle/role/terraform-role/secret-id

Export them into Terraform variables (terraform.tfvars or environment vars):
vault_role_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
vault_secret_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"

▶️ Usage

Initialize Terraform:
terraform init

Apply configuration:
terraform apply -auto-approve

Terraform will:

Authenticate with Vault via AppRole.

Read secrets from secret/data/ec2-tag.

Launch an EC2 instance with those secrets injected as tags.

📤 Outputs

EC2 Public IP

Vault secret (password) → marked as sensitive
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

ec2_public_ip = "54.xxx.xxx.xxx"
ec2_secret = (sensitive value)

🔐 Security Notes

In production, avoid exporting secrets as Terraform outputs.

Consider ephemeral KV secrets for avoiding secret persistence in Terraform state.

Always restrict Vault policies to the minimum required access.
























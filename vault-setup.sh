#!/bin/bash
# Quick Vault Setup Script
# Run this after creating your HCP Vault cluster

set -e

echo "🔐 HashiCorp Vault Setup for Terraform"
echo "======================================"
echo ""

# Get Vault address
read -p "Enter your Vault address (https://vault-xxxxx.vault.11b0221a.budgets.hcp-demo.com): " VAULT_ADDR
export VAULT_ADDR=$VAULT_ADDR

# Get token
read -sp "Enter your Vault root token (for initial setup): " VAULT_TOKEN
export VAULT_TOKEN=$VAULT_TOKEN
echo ""

# Verify connection
echo ""
echo "Testing Vault connection..."
if vault status > /dev/null 2>&1; then
  echo "✅ Connected to Vault"
else
  echo "❌ Failed to connect to Vault"
  exit 1
fi

# Enable JWT auth
echo ""
echo "🔑 Enabling JWT authentication..."
vault auth enable jwt 2>/dev/null || echo "JWT already enabled"

# Configure JWT
echo "Configuring JWT with GitLab OIDC..."
vault write auth/jwt/config \
  jwks_url="https://gitlab.com/oauth/openid_connect/certs" \
  bound_issuer="https://gitlab.com" \
  -f

# Create JWT role
vault write auth/jwt/role/gitlab-role \
  bound_audiences="https://gitlab.com" \
  user_claim="user_login" \
  role_type="jwt" \
  policies="terraform-policy" \
  -f

echo "✅ JWT auth configured"

# Create policy
echo ""
echo "📋 Creating terraform policy..."
vault policy write terraform-policy - << EOF
path "secret/data/azure/terraform/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/azure/terraform/*" {
  capabilities = ["list"]
}
EOF

echo "✅ Policy created"

# Store secrets
echo ""
echo "🔐 Storing ARM credentials in Vault..."
read -p "Enter ARM_CLIENT_ID: " ARM_CLIENT_ID
read -sp "Enter ARM_CLIENT_SECRET: " ARM_CLIENT_SECRET
echo ""
read -p "Enter ARM_SUBSCRIPTION_ID: " ARM_SUBSCRIPTION_ID
read -p "Enter ARM_TENANT_ID: " ARM_TENANT_ID

vault kv put secret/azure/terraform/arm \
  client_id="$ARM_CLIENT_ID" \
  client_secret="$ARM_CLIENT_SECRET" \
  subscription_id="$ARM_SUBSCRIPTION_ID" \
  tenant_id="$ARM_TENANT_ID"

echo "✅ ARM credentials stored in Vault"

# Verify
echo ""
echo "Verifying secrets..."
vault kv get secret/azure/terraform/arm

echo ""
echo "✅ Vault setup complete!"
echo ""
echo "Next steps:"
echo "1. Add these GitLab CI/CD variables:"
echo "   - VAULT_ADDR: $VAULT_ADDR"
echo "   - VAULT_JWT_ROLE: gitlab-role"
echo "   - VAULT_SECRET_PATH: secret/data/azure/terraform/arm"
echo ""
echo "2. Push the updated .gitlab-ci.yml to GitLab"
echo ""
echo "3. Go to Pipelines and click Play to deploy!"

# HashiCorp Vault + GitLab CI/CD Integration Guide

Secure secrets management for your Azure Terraform deployments.

## Architecture

```
┌──────────────┐
│   GitLab     │
│  Pipeline    │
└──────┬───────┘
       │
       │ 1. Get JWT token
       ↓
┌──────────────────────┐
│   GitLab JWT Auth    │
│   (OIDC Provider)    │
└──────┬───────────────┘
       │
       │ 2. Exchange JWT for Vault token
       ↓
┌──────────────────────┐
│   HCP Vault Cloud    │
│  (Secrets Manager)   │
└──────┬───────────────┘
       │
       │ 3. Fetch ARM credentials
       ↓
┌──────────────────────┐
│   Terraform Deploy   │
│   (Uses secrets)     │
└──────────────────────┘
```

## Setup Steps

### Step 1: Create HCP Vault Cluster (10 minutes)

1. Go to https://cloud.hashicorp.com/
2. Sign up for free account (if needed)
3. Click **Create a cluster**
4. Fill in:
   - **Cluster name**: `2026-secrets`
   - **Region**: US (same as your Azure region recommended)
   - **Tier**: Standard (free tier available)
5. Click **Create cluster**
6. Wait for cluster to be ready (5-10 minutes)

### Step 2: Configure Vault

Once cluster is ready:

1. Click **Manage** on your cluster
2. Copy **Vault address** – looks like: `https://vault-xxxxx.vault.11b0221a.budgets.hcp-demo.com`
3. Go to **Access control** → **Service principals**
4. Create new service principal:
   - Name: `gitlab-ci`
   - Leave defaults, click **Create**
5. Copy the **Client ID** and **Client secret**

### Step 3: Configure JWT Auth in Vault

1. In Vault, go to **Auth methods**
2. Enable **JWT** auth method
3. Configure with GitLab OIDC:

```bash
# Via Vault CLI
vault auth enable jwt

vault write auth/jwt/config \
  jwks_url="https://gitlab.com/oauth/openid_connect/certs" \
  bound_issuer="https://gitlab.com"

vault write auth/jwt/role/gitlab-role \
  bound_audiences="https://gitlab.com" \
  user_claim="user_login" \
  role_type="jwt" \
  policies="terraform-policy"
```

### Step 4: Create Vault Policy

Policy to allow Terraform to read secrets:

```hcl
# Save as terraform-policy.hcl
path "secret/data/azure/terraform/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/azure/terraform/*" {
  capabilities = ["list"]
}
```

Apply policy:

```bash
vault policy write terraform-policy terraform-policy.hcl
```

### Step 5: Store ARM Credentials in Vault

```bash
vault kv put secret/azure/terraform/arm \
  client_id="<YOUR_CLIENT_ID>" \
  client_secret="<YOUR_CLIENT_SECRET>" \
  subscription_id="<YOUR_SUBSCRIPTION_ID>" \
  tenant_id="<YOUR_TENANT_ID>"
```

**Example values (from your Service Principal):**
```
client_id: 6dbf7aee-38f6-4539-9ee7-c65c982ba557
client_secret: [from 'az ad sp create-for-rbac' output - keep secret!]
subscription_id: f1840e41-e99d-4419-ba81-750d21ae7135
tenant_id: 8abc82df-9666-4d89-8010-d7f5047e367c
```

### Step 6: Configure GitLab to Use Vault

1. Go to https://gitlab.com/ubs-group6303709/ubs-project/settings/ci_cd
2. Add these **Variables** (Protected, Masked):

| Key | Value |
|-----|-------|
| `VAULT_ADDR` | https://vault-xxxxx.vault.11b0221a.budgets.hcp-demo.com |
| `VAULT_JWT_ROLE` | gitlab-role |
| `VAULT_SECRET_PATH` | secret/data/azure/terraform/arm |

3. **Optional**: Add GitLab OIDC audience (if using JWT auth):

```
VAULT_ISSUER: https://gitlab.com
VAULT_AUDIENCE: https://gitlab.com
```

## Updated .gitlab-ci.yml

Your pipeline will fetch secrets from Vault at runtime:

```yaml
stages:
  - validate
  - plan
  - apply

variables:
  TERRAFORM_VERSION: "1.5"
  TF_ROOT: "${CI_PROJECT_DIR}/DevOps/environments/dev"
  VAULT_ADDR: "$VAULT_ADDR"  # Set in GitLab variables
  VAULT_JWT_ROLE: "$VAULT_JWT_ROLE"

image: 
  name: hashicorp/terraform:${TERRAFORM_VERSION}
  entrypoint: [""]

before_script:
  - cd ${TF_ROOT}
  
  # Fetch secrets from Vault using JWT
  - |
    export VAULT_TOKEN=$(curl -s --request POST \
      --data @- ${VAULT_ADDR}/v1/auth/jwt/login \
      <<< "{\"role\":\"${VAULT_JWT_ROLE}\",\"jwt\":\"${CI_JOB_JWT}\"}" \
      | jq -r '.auth.client_token')
  
  # Retrieve ARM credentials from Vault
  - |
    VAULT_SECRET=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
      "${VAULT_ADDR}/v1/${VAULT_SECRET_PATH}")
  
  - |
    export ARM_CLIENT_ID=$(echo $VAULT_SECRET | jq -r '.data.data.client_id')
    export ARM_CLIENT_SECRET=$(echo $VAULT_SECRET | jq -r '.data.data.client_secret')
    export ARM_SUBSCRIPTION_ID=$(echo $VAULT_SECRET | jq -r '.data.data.subscription_id')
    export ARM_TENANT_ID=$(echo $VAULT_SECRET | jq -r '.data.data.tenant_id')
  
  - terraform --version

validate:
  stage: validate
  script:
    - echo "🔍 Validating Terraform configuration..."
    - terraform init -backend=false
    - terraform validate
  only:
    - merge_requests
    - main

plan:
  stage: plan
  script:
    - echo "📊 Running Terraform plan..."
    - terraform init
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan
    expire_in: 7 days
  only:
    - merge_requests
    - main

apply:
  stage: apply
  script:
    - echo "🚀 Applying Terraform configuration..."
    - terraform init
    - terraform apply -auto-approve tfplan
    - terraform output
  dependencies:
    - plan
  only:
    - main
  when: manual
```

## Security Benefits

✅ **No secrets in GitLab**: Only Vault URL and role stored
✅ **Short-lived tokens**: JWT tokens expire quickly
✅ **Audit trail**: All secret access logged in Vault
✅ **Centralized management**: Update secrets in one place
✅ **Rotation friendly**: Change secrets without updating GitLab
✅ **Multiple environments**: Store different secrets per env
✅ **Compliance**: Meets security standards (SOC2, etc.)

## Troubleshooting

### JWT authentication fails

```bash
# Verify JWT is valid
echo $CI_JOB_JWT | jq -R 'split(".") | .[1] | @base64d | fromjson'
```

### Can't reach Vault

- Check `VAULT_ADDR` is correct
- Verify cluster is running
- Check network/firewall rules

### Permission denied

- Verify policy includes correct paths
- Check role configuration
- Ensure user has policy attached

## Next Steps

1. ✅ Create HCP Vault cluster
2. ✅ Store ARM credentials in Vault
3. ✅ Update GitLab variables (just VAULT_ADDR, VAULT_JWT_ROLE, VAULT_SECRET_PATH)
4. ✅ Update .gitlab-ci.yml with Vault integration
5. ✅ Push changes to GitLab
6. 🚀 Deploy!

---

This approach provides enterprise-grade secrets management while keeping your CI/CD simple and secure!

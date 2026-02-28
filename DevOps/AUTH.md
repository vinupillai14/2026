# Azure Authentication for Terraform

This document explains the various authentication methods available for deploying infrastructure with Terraform.

## Local Development (Recommended)

### Azure CLI Authentication

**Best for**: Local development and testing

**Setup**:

1. Install Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli
2. Login to Azure:
```bash
az login
```

3. Set your subscription (if you have multiple):
```bash
az account set --subscription <subscription-id>
```

4. Run Terraform:
```bash
cd DevOps/environments/dev
terraform init
terraform plan
terraform apply
```

**Benefits**:
- ✅ No credentials in code or environment variables
- ✅ Automatic token refresh
- ✅ Uses your Azure AD identity
- ✅ Secure and simple

**How it works**:
- Azure CLI stores access tokens in `~/.azure/`
- Terraform automatically detects and uses them via the `AzureRM` provider
- No provider configuration needed for authentication

---

## CI/CD Pipelines (GitHub Actions / Azure DevOps)

### OIDC (OpenID Connect) - Best Practice

**Best for**: GitHub Actions, GitLab CI, AWS GitHub, etc.

**One-time Azure Setup**:

```bash
# Get your GitHub repo details
GITHUB_ORG="vinupillai14"
GITHUB_REPO="2026"
GITHUB_BRANCH="main"

# Create Azure AD App
az ad app create --display-name "github-terraform"

# Create Service Principal
az ad sp create --id <app-id>

# Get credentials needed for GitHub secrets
az ad app show --id <app-id> --query appId -o tsv       # Client ID
az ad app show --id <app-id> --query id -o tsv           # Object ID
az account show --query id -o tsv                         # Subscription ID
az account show --query tenantId -o tsv                   # Tenant ID
```

**GitHub Secrets Setup**:

In your GitHub repo, add these secrets:
- `AZURE_CLIENT_ID`: Service principal client ID
- `AZURE_TENANT_ID`: Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

**GitHub Actions Workflow Example**:

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]
    paths:
      - 'DevOps/**'

permissions:
  id-token: write
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: |
          cd DevOps/environments/${{ matrix.environment }}
          terraform init
        env:
          ARM_USE_OIDC: true
      
      - name: Terraform Plan
        run: |
          cd DevOps/environments/${{ matrix.environment }}
          terraform plan
        env:
          ARM_USE_OIDC: true
      
      - name: Terraform Apply
        run: |
          cd DevOps/environments/${{ matrix.environment }}
          terraform apply -auto-approve
        env:
          ARM_USE_OIDC: true
```

**Benefits**:
- ✅ No client secrets stored
- ✅ Federated credentials (token-based)
- ✅ Short-lived tokens
- ✅ Audit trail via GitHub
- ✅ Better security posture

---

## Alternative Methods (Not Recommended)

### Service Principal with Client Secret

**Not recommended** due to:
- ❌ Secrets stored in environment variables or files
- ❌ Manual rotation required
- ❌ Security risk if exposed

If you must use this:

```bash
# Create service principal
az ad sp create-for-rbac --role "Contributor" \
  --scopes /subscriptions/<subscription-id>

# Export credentials
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"

# Run Terraform
terraform apply
```

### Managed Identity (For Azure VMs/AKS)

**Best for**: Running Terraform from within Azure infrastructure (VM, AKS, App Service)

```bash
# Terraform automatically detects managed identity
# No configuration needed!
```

---

## Troubleshooting

### "Authorization failed" error

```bash
# Check current Azure CLI login
az account show

# Re-login if needed
az logout
az login

# Verify subscription
az account list
```

### "The client does not have authorization to perform action..."

The logged-in user or service principal needs the appropriate RBAC role. Assign `Contributor` or `Owner` role on the subscription:

```bash
# Check your current permissions
az role assignment list --assignee <your-email> --subscription <sub-id>

# Assign role (requires Owner/Admin)
az role assignment create --role "Contributor" \
  --assignee <user-object-id> \
  --scope /subscriptions/<subscription-id>
```

### Token Expiration

Azure CLI tokens expire after a few hours of inactivity:

```bash
# Refresh token
az account get-access-token

# Or just run terraform again - it will refresh automatically
```

---

## Recommendation Summary

| Scenario | Method | Security | Ease |
|----------|--------|----------|------|
| Local development | Azure CLI | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| GitHub Actions CI/CD | OIDC | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Azure VM/AKS | Managed Identity | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Legacy/other | Service Principal | ⭐⭐ | ⭐⭐⭐⭐ |

**Default setup for this project**: Azure CLI for local use + OIDC for CI/CD.

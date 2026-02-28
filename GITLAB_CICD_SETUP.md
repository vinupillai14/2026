# GitLab CI/CD Setup for Terraform AKS Deployment

This guide explains how to set up GitLab CI/CD for automated Terraform deployments to Azure AKS.

## Overview

The `.gitlab-ci.yml` pipeline provides:
- **Validate stage**: Runs on every push/MR to check Terraform syntax
- **Plan stage**: Generates deployment plan and stores artifacts
- **Apply stage**: Manually triggered to apply changes (safety measure)
- **Destroy stage**: Manual-only destruction for cleanup

## Prerequisites

- GitLab repository (self-hosted or gitlab.com)
- Azure subscription
- Azure CLI installed locally
- Service Principal created with Contributor role

## Step 1: Create Azure Service Principal

The Service Principal is what GitLab CI/CD will use to authenticate with Azure.

### One-time Setup

```bash
# Set your subscription
SUBSCRIPTION_ID="f1840e41-e99d-4419-ba81-750d21ae7135"
az account set --subscription $SUBSCRIPTION_ID

# Create the service principal
az ad sp create-for-rbac \
  --name "gitlab-terraform-2026" \
  --role "Contributor" \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --json-auth
```

Save the output — it will include:
- `clientId`
- `clientSecret`
- `subscriptionId`
- `tenantId`

**⚠️ Important**: The `clientSecret` won't be shown again. Save it securely.

### Verify Permissions

```bash
# Check the Service Principal has correct role
az role assignment list \
  --assignee "gitlab-terraform-2026" \
  --subscription $SUBSCRIPTION_ID
```

## Step 2: Add GitLab CI/CD Variables

Store Service Principal credentials as GitLab CI/CD variables so the pipeline can use them.

### Via GitLab Web UI

1. Go to your GitLab project
2. Navigate to **Settings** → **CI/CD** → **Variables**
3. Click **Add variable** and add each (mark as **Protected** and **Masked**):

| Variable Name | Value | Protected | Masked |
|--------------|-------|-----------|--------|
| `ARM_CLIENT_ID` | clientId from SP | ✅ | ✅ |
| `ARM_CLIENT_SECRET` | clientSecret from SP | ✅ | ✅ |
| `ARM_SUBSCRIPTION_ID` | subscriptionId | ✅ | ✅ |
| `ARM_TENANT_ID` | tenantId | ✅ | ✅ |

These environment variables are automatically picked up by Terraform's Azure provider.

### Via GitLab CLI (if available)

```bash
# Add variables
gitlab variable create \
  --key ARM_CLIENT_ID \
  --value "your-client-id" \
  --protected \
  --masked
```

## Step 3: Push and Trigger Pipeline

The pipeline runs automatically when you push to the repository.

### How It Works

```
Push to GitLab
    ↓
    ├─→ Validate: Check Terraform syntax ✓
    ├─→ Format Check: Check code formatting (optional)
    ├─→ Plan: Generate deployment plan 
    └─→ Apply: (Manual) Deploy to AKS
```

### Workflow

1. **Create feature branch and make changes**
   ```bash
   git checkout -b feat/add-storage
   # ... make changes ...
   git push origin feat/add-storage
   ```

2. **Pipeline runs automatically**
   - Validates Terraform syntax
   - Generates plan
   - You'll see results in merge request

3. **Merge to main**
   ```bash
   # Create merge request
   # After approval, merge to main
   ```

4. **Manually trigger apply (on main)**
   - Go to **CI/CD** → **Pipelines**
   - Click the `apply` job's **Play** button
   - Terraform will apply the changes

## Pipeline Stages

### ✅ Validate Stage

Runs on every push and merge request.

```yaml
validate:
  - Terraform init (no backend)
  - Terraform validate
  - Check code syntax
```

Fails if syntax is invalid. You must fix errors before merging.

### 📊 Plan Stage

Also runs on every push/MR.

```yaml
plan:
  - Terraform init
  - Terraform plan
  - Saves plan artifact
```

Plan artifacts are available for 7 days. Useful for reviewing changes.

### 🚀 Apply Stage

**Manual trigger only** for safety (prevents accidental deployments).

```yaml
apply (manual):
  - Terraform init
  - Terraform apply -auto-approve tfplan
  - Output cluster details
```

**To apply:**
1. Go to **CI/CD** → **Pipelines** (on main branch)
2. Find the latest pipeline
3. Click the **Play** button next to the `apply` job
4. Confirm

### 🗑️ Destroy Stage

**Manual trigger only** for cleanup.

```yaml
destroy (manual):
  - Terraform destroy -auto-approve
  - Removes all resources
```

## Monitoring Deployments

### View Pipeline Status

1. Go to **CI/CD** → **Pipelines**
2. Click pipeline to see job details
3. Click job name to view logs

### Pipeline Artifacts

Terraform plans and outputs are saved for 7 days:
- Go to **Pipelines** → Click pipeline
- Click **Artifacts** to download plan file
- Useful for auditing changes

### Check AKS Deployment Status

After apply completes:

```bash
# List resource groups
az group list --query "[?starts_with(name, 'rg-dev')].name"

# Check AKS cluster
az aks list -g rg-dev-2026

# Get cluster credentials
az aks get-credentials -g rg-dev-2026 -n aks-dev-2026

# Verify nodes
kubectl get nodes
```

## Customization

### Deploy Preprod Also

Update `.gitlab-ci.yml` to create separate jobs:

```yaml
plan:dev:
  # ... existing plan config ...
  variables:
    TF_ROOT: "${CI_PROJECT_DIR}/DevOps/environments/dev"

plan:preprod:
  # ... same as above but ...
  variables:
    TF_ROOT: "${CI_PROJECT_DIR}/DevOps/environments/preprod"

apply:dev:
  # ... existing apply config ...

apply:preprod:
  # ... same as apply:dev but ...
```

### Require Approval Before Apply

Add approval rules in GitLab project settings:

1. **Settings** → **Merge requests**
2. **Approval rules** → Create rule
3. Require N approvals before merge

This ensures human review before production changes.

### Change Trigger Conditions

Only run on specific branches:

```yaml
only:
  - main
  - merge_requests
  # Add branches here
```

Or use `except` to skip certain branches:

```yaml
except:
  - tags
  - schedules
```

## Troubleshooting

### "Terraform init failed"

Usually service principal credentials are missing:

```bash
# Check variables are set
echo $ARM_CLIENT_ID  # Should be set
echo $ARM_CLIENT_SECRET  # Should be set

# In GitLab, verify variables in Settings → CI/CD → Variables
```

### "Authorization failed"

Service Principal doesn't have permissions:

```bash
# Verify SP has Contributor role
az role assignment list --assignee "gitlab-terraform-2026"

# Re-assign if needed
az role assignment create \
  --role "Contributor" \
  --assignee-object-id <sp-object-id> \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

### Pipeline Timeout

Terraform operations are taking too long:

Update `.gitlab-ci.yml`:

```yaml
apply:
  timeout: 1 hour  # Increase from default 60 mins
```

### State Lock Issues

If previous apply didn't complete cleanly:

```bash
# Force unlock terraform state
terraform force-unlock <LOCK_ID>
```

## Security Best Practices

1. **Protect sensitive variables**
   - Set **Protected** flag on CI/CD variables
   - Set **Masked** flag so values don't appear in logs

2. **Require branch protection**
   - **Settings** → **Protected branches**
   - Require approvals before merge
   - Require pipeline to pass

3. **Audit deployments**
   - Check **Pipeline** history for who deployed what
   - Review merge requests for changes
   - Use GitLab's audit logs

4. **Rotate credentials regularly**
   ```bash
   # Regenerate every 90 days
   az ad sp credential reset --name "gitlab-terraform-2026"
   # Update GitLab variables with new clientSecret
   ```

5. **Enable MFA**
   - For GitLab user accounts
   - For Azure admin accounts managing subscriptions

## Next Steps

1. ✅ Create Service Principal (Step 1)
2. ✅ Add GitLab CI/CD variables (Step 2)
3. ✅ Push code to trigger validation
4. 📊 Review plan in pipeline artifacts
5. 🚀 Manually click apply to deploy AKS
6. ✅ Verify cluster with kubectl

## Support

For issues:
- Check pipeline logs: **CI/CD** → **Pipelines** → click job
- View Terraform errors in `apply` step
- Verify variables are set: **Settings** → **CI/CD** → **Variables**
- Run locally to debug: `cd DevOps/environments/dev && terraform apply`

## Additional Resources

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform State Management](https://www.terraform.io/language/state)

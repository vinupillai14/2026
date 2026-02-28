# Terraform Backend Setup

This document explains how to set up the remote Terraform state backend in Azure Blob Storage.

## Why Remote State?

- ✅ **Central** - All team members use same state
- ✅ **Secure** - Encrypted in Azure Blob Storage
- ✅ **Locked** - Prevents concurrent modifications
- ✅ **Auditable** - Track changes via Azure Storage logs
- ✅ **Recoverable** - Built-in versioning support

## Architecture

```
Azure Subscription
└── Resource Group: rg-terraform-backend
    └── Storage Account: tfstateacct001
        └── Container: tfstate
            ├── dev.tfstate
            └── preprod.tfstate
```

## Setup Instructions

### Step 1: Prerequisites

Ensure you have:
- Service Principal credentials (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID)
- Terraform installed locally (v1.5+)
- Azure CLI (optional, for verification)

### Step 2: Set Environment Variables

```bash
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```

### Step 3: Run Bootstrap Script

```bash
cd /path/to/2026-coding-project
chmod +x bootstrap.sh
./bootstrap.sh
```

This will:
1. Create resource group: `rg-terraform-backend`
2. Create storage account: `tfstateacct001` (GRS for redundancy)
3. Create container: `tfstate`
4. Store both `dev.tfstate` and `preprod.tfstate`

### Step 4: Verify Backend Creation

```bash
# List storage accounts
az storage account list -g rg-terraform-backend

# List containers
az storage container list \
  --account-name tfstateacct001 \
  --account-key <key>

# Check for state files
az storage blob list \
  --container-name tfstate \
  --account-name tfstateacct001
```

## State File Details

**Dev Environment State:**
- Path: `tfstate/dev.tfstate`
- Contains: AKS cluster, storage account for dev
- Locked during terraform operations

**Preprod Environment State:**
- Path: `tfstate/preprod.tfstate`
- Contains: AKS cluster, storage account for preprod
- Locked during terraform operations

## First Deploy with Backend

When you run `terraform init` in dev/preprod:

```bash
cd DevOps/environments/dev
terraform init
# Terraform will detect backend.tf and:
# 1. Create Blob Storage client
# 2. Authenticate with ARM credentials
# 3. Download state file (if exists)
# 4. Lock state for operations
```

## State Locking

Terraform automatically locks the state file during operations:

```
terraform plan   → State locked for read
terraform apply  → State locked for read/write
             ↓ (lock released when complete)
```

This prevents concurrent modifications that could corrupt state.

## Troubleshooting

### Error: "Container not found"

Ensure bootstrap completed successfully:
```bash
az storage container exists \
  --name tfstate \
  --account-name tfstateacct001
```

### Error: "Access Denied"

Check Service Principal permissions:
```bash
az role assignment list \
  --assignee your-service-principal-id \
  --output table
```

Should have "Contributor" role on subscription.

### Error: "Failed to acquire lock"

Another terraform operation is running. Wait or manually release:
```bash
# Check lock (from Azure CLI)
az storage blob show \
  --container-name tfstate \
  --name dev.tfstate.lock \
  --account-name tfstateacct001
```

## Manual Backend Creation (if bootstrap fails)

If the script fails, create manually:

```bash
# 1. Create resource group
az group create -n rg-terraform-backend -l eastus

# 2. Create storage account (GRS = geo-redundant)
az storage account create \
  -n tfstateacct001 \
  -g rg-terraform-backend \
  -l eastus \
  --sku Standard_GRS \
  --https-only true

# 3. Create container
az storage container create \
  -n tfstate \
  --account-name tfstateacct001 \
  --auth-mode login

# 4. Enable versioning (optional backup)
az storage account blob-service-properties update \
  --account-name tfstateacct001 \
  --enable-versioning
```

## Cleanup (if needed)

⚠️ **WARNING**: This deletes all state files!

```bash
# Delete everything
az group delete -n rg-terraform-backend --yes
```

This removes the storage account and all state files. Only do this if you're completely removing the infrastructure.

## Best Practices

✅ **Do:**
- Use GRS (geo-redundant) for production
- Enable Storage Account versioning for recovery
- Rotate storage account keys regularly
- Use separate state files per environment
- Lock state files with Azure RBAC

❌ **Don't:**
- Store state files in Git
- Share storage account keys
- Use LRS for production (no redundancy)
- Manually modify state files
- Delete containers with active deployments

## References

- [Terraform Azure Backend Documentation](https://www.terraform.io/language/settings/backends/azurerm)
- [Azure Storage Security Best Practices](https://docs.microsoft.com/en-us/azure/storage/common/storage-security-guide)
- [Terraform State Locking](https://www.terraform.io/language/state/locking)

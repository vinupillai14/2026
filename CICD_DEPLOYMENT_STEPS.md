# 🚀 Complete CI/CD Pipeline Setup for Deploying AKS to Azure

This is your end-to-end guide to deploy Azure Kubernetes Service (AKS) using GitLab CI/CD with Terraform.

## What You Have

✅ **Terraform Modules** (in DevOps folder):
- `terraform/azure_storage_account/` - Storage account module
- `terraform/aks/` - AKS cluster module
- `environments/dev/` - Dev environment config (will deploy here)
- `environments/preprod/` - Preprod config (optional)

✅ **GitLab CI/CD Pipeline** (.gitlab-ci.yml):
- Automatic syntax validation on every push
- Automatic terraform plan generation
- Manual approval before deploying (safety measure)
- Destroy option for cleanup

✅ **Repository**: Already migrated to GitLab
- https://gitlab.com/ubs-group6303709/ubs-project

## Your Architecture

```
┌─────────────┐
│   GitLab    │  You push code
│  (This is   │──────┐
│   your CI   │      │ Webhook
│   /CD)      │      ↓
└─────────────┘  ┌──────────────────┐
                 │ GitLab Runner    │
                 │                  │
                 │ 1. Validate      │ (automatic)
                 │ 2. Plan          │ (automatic)
                 │ 3. Ask for Apply │ (manual click)
                 │ 4. Deploy        │ (you click Play)
                 └─────────┬────────┘
                           │
                           ↓
                    ┌──────────────┐
                    │    Azure     │
                    │              │
                    │  Resource    │
                    │  Group       │
                    │     ↓        │
                    │   Storage    │
                    │   Account    │
                    │     ↓        │
                    │    AKS       │
                    │  Cluster     │
                    └──────────────┘
```

## 3-Step Deployment Setup

### Step 1: Create Azure Service Principal (1 minute)

This is what GitLab will use to authenticate with Azure.

**In your terminal (macOS):**

```bash
# Open browser and login to Azure
az login

# Set subscription
SUBSCRIPTION_ID="85616346-9563-4a83-86dd-dcbb2dc6e237"
az account set --subscription $SUBSCRIPTION_ID

# Create service principal
az ad sp create-for-rbac \
  --name "gitlab-terraform-2026" \
  --role "Contributor" \
  --scopes /subscriptions/$SUBSCRIPTION_ID
```

**The output will look like:**
```json
{
  "appId": "12345678-1234-1234-1234-123456789012",
  "displayName": "gitlab-terraform-2026",
  "password": "abcdefghijklmnopqrstuvwxyz~ABCDEF",
  "tenant": "87654321-4321-4321-4321-210987654321"
}
```

**Copy these 4 values:**
- `appId` → will become `ARM_CLIENT_ID`
- `password` → will become `ARM_CLIENT_SECRET`
- `tenant` → will become `ARM_TENANT_ID`
- `85616346-9563-4a83-86dd-dcbb2dc6e237` → `ARM_SUBSCRIPTION_ID`

### Step 2: Add Credentials to GitLab (2 minutes)

1. Go to: https://gitlab.com/ubs-group6303709/ubs-project

2. Click **Settings** (left sidebar) → **CI/CD** → **Variables**

3. Click blue **Add variable** button

4. Add each variable (**IMPORTANT: Check Protected ✅ and Masked ✅**):

| Variable Name | Value | Protected | Masked |
|---|---|---|---|
| `ARM_CLIENT_ID` | appId from step 1 | ✅ | ✅ |
| `ARM_CLIENT_SECRET` | password from step 1 | ✅ | ✅ |
| `ARM_SUBSCRIPTION_ID` | 85616346-9563-4a83-86dd-dcbb2dc6e237 | ✅ | ✅ |
| `ARM_TENANT_ID` | tenant from step 1 | ✅ | ✅ |

### Step 3: Deploy to AKS (5 minutes)

1. Go to: https://gitlab.com/ubs-group6303709/ubs-project/pipelines

2. Wait for the **validate** and **plan** jobs to show green checkmarks ✅

3. Find the **apply** job and click the blue **Play ▶️** button

4. Watch the logs as Terraform deploys (takes 10-20 minutes)

## What Gets Deployed

**Dev Environment**:
- ✅ Resource Group: `rg-dev-2026`
- ✅ Storage Account: `stgdevacct001` (Standard-LRS)
- ✅ AKS Cluster: `aks-dev-2026` (2-4 nodes, auto-scaling)

**Estimated Cost**: ~$300-400/month in Azure

## Quick Reference

| Step | What | Where | Time |
|------|------|-------|------|
| 1 | Create SP | macOS terminal | 1 min |
| 2 | Add variables | GitLab web UI | 2 min |
| 3 | Deploy | GitLab CI/CD (click Play) | 15-20 min |

---

**Total time to deploy AKS: ~20-25 minutes!**

Your complete CI/CD pipeline is ready. Now just:
1. Run the commands in Step 1
2. Add the values in Step 2
3. Click Play in Step 3

🚀 Let's deploy!

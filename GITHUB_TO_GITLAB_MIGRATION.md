# GitHub to GitLab Migration Guide

This guide walks you through migrating your Terraform repository from GitHub to GitLab.

## Prerequisites

- GitLab account (create at https://gitlab.com or use self-hosted)
- Git CLI installed locally
- Access to your GitHub repo

## Step 1: Create GitLab Project

### Via GitLab Web UI

1. Go to https://gitlab.com (or your self-hosted instance)
2. Click **Create project**
3. Choose **Create blank project**
4. Fill in details:
   - **Project name**: `2026`
   - **Project slug**: `2026` (auto-filled)
   - **Visibility**: Private (or Public if desired)
   - **Initialize with README**: No (we'll push existing repo)
5. Click **Create project**

### Via GitLab CLI (if installed)

```bash
gitlab project create \
  --name "2026" \
  --visibility private
```

After creation, you'll see your project URL (e.g., `https://gitlab.com/your-username/2026.git`)

## Step 2: Mirror GitHub Repo to GitLab

### Method 1: Push as Mirror (Recommended)

This clones all branches and history in one command:

```bash
# Clone GitHub repo as mirror with full history
git clone --mirror https://github.com/vinupillai14/2026.git

# Enter the mirror directory
cd 2026.git

# Push everything to GitLab
git push --mirror https://your-username:your-access-token@gitlab.com/your-username/2026.git

# Clean up
cd ..
rm -rf 2026.git
```

### Method 2: Traditional Clone and Push

```bash
# Clone the GitHub repo
git clone https://github.com/vinupillai14/2026.git
cd 2026

# Change remote to GitLab
git remote set-url origin https://your-username:your-access-token@gitlab.com/your-username/2026.git

# Push everything
git push -u origin --all
git push -u origin --tags

# Verify
git remote -v
```

## Step 3: Set Up GitLab Access Token

To authenticate without entering password each time, create a Personal Access Token:

### Create Access Token

1. Go to **User Profile** (top right) → **Preferences**
2. Click **Access Tokens** (left sidebar)
3. Fill in:
   - **Token name**: `terraform-deploy`
   - **Scopes**: Check `api`, `read_repository`, `write_repository`
   - **Expiration date**: 1 year (or as needed)
4. Click **Create personal access token**
5. **Copy the token immediately** (you won't see it again)

### Configure Git to Use Token

```bash
# Update local repo
cd ~/path/to/2026
git remote set-url origin https://your-username:YOUR_ACCESS_TOKEN@gitlab.com/your-username/2026.git

# Test authentication
git pull
```

Store token securely (Git credential manager, 1Password, etc.)

## Step 4: Create Azure Service Principal

```bash
SUBSCRIPTION_ID="f1840e41-e99d-4419-ba81-750d21ae7135"
az account set --subscription $SUBSCRIPTION_ID

# Create service principal
az ad sp create-for-rbac \
  --name "gitlab-terraform-2026" \
  --role "Contributor" \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --json-auth
```

**Save the output** — you'll need these values:
- `clientId` → `ARM_CLIENT_ID`
- `clientSecret` → `ARM_CLIENT_SECRET`
- `subscriptionId` → `ARM_SUBSCRIPTION_ID`
- `tenantId` → `ARM_TENANT_ID`

## Step 5: Add GitLab CI/CD Variables

### Via GitLab Web UI

1. In your GitLab project, go to **Settings** → **CI/CD** → **Variables** (left sidebar under "Integrate")
2. Click **Add variable** and add each:

| Variable Name | Value | Protected | Masked |
|--------------|-------|-----------|--------|
| `ARM_CLIENT_ID` | clientId from Step 4 | ✅ | ✅ |
| `ARM_CLIENT_SECRET` | clientSecret from Step 4 | ✅ | ✅ |
| `ARM_SUBSCRIPTION_ID` | f1840e41-e99d-4419-ba81-750d21ae7135 | ✅ | ✅ |
| `ARM_TENANT_ID` | tenantId from Step 4 | ✅ | ✅ |

**Ensure both Protected and Masked are checked** ✅

### Via GitLab API

```bash
GITLAB_URL="https://gitlab.com"
PROJECT_ID="your-project-id"
TOKEN="your-access-token"

# Get project ID
curl --header "PRIVATE-TOKEN: $TOKEN" "$GITLAB_URL/api/v4/projects?search=2026"

# Add variables
curl --request POST \
  --header "PRIVATE-TOKEN: $TOKEN" \
  --form "key=ARM_CLIENT_ID" \
  --form "value=your-client-id" \
  --form "protected=true" \
  --form "masked=true" \
  "$GITLAB_URL/api/v4/projects/$PROJECT_ID/variables"
```

## Step 6: Verify CI/CD Setup

### Check Pipeline Configuration

1. In GitLab project, go to **CI/CD** → **Pipelines**
2. You should see `.gitlab-ci.yml` detected

### Trigger First Pipeline

Create a small test commit and push:

```bash
# Make a change
echo "# Migrated to GitLab" >> README.md

# Commit and push
git add README.md
git commit -m "chore: migrate to gitlab"
git push origin main
```

### Monitor Pipeline

1. Go to **CI/CD** → **Pipelines**
2. Click the pipeline to see stages:
   - ✅ **Validate** should pass
   - ✅ **Format Check** (optional)
   - ✅ **Plan** should generate plan

If any stage fails:
- Click the failed job name
- Check logs for error details
- Fix and push again

## Step 7: Deploy to AKS

Once pipeline shows green (all validations pass):

1. Go to **CI/CD** → **Pipelines** (latest run)
2. Click **Play** (▶️) button next to `apply` job
3. Confirm deployment
4. Watch logs as Terraform applies

### Verify Deployment

```bash
# Check Azure resources were created
az group list --query "[?starts_with(name, 'rg-dev')].name"

# Get AKS cluster credentials
az aks get-credentials -g rg-dev-2026 -n aks-dev-2026

# List nodes
kubectl get nodes
```

## Step 8: Update Your Local Git Config (Optional)

Update any local documentation that references GitHub:

```bash
# Update local remotes if needed
git remote -v  # Should show gitlab.com
```

## Troubleshooting

### "Invalid credentials" during mirror push

```bash
# Create GitLab access token (Step 3)
# Use token as password instead of GitLab password
```

### Pipeline shows "No CI/CD configuration found"

```bash
# Verify .gitlab-ci.yml is in root directory
ls -la .gitlab-ci.yml

# If missing, you need to push the code with CI config
git add .gitlab-ci.yml
git commit -m "add gitlab ci/cd"
git push
```

### Variables not recognized in pipeline

1. Double-check variable names match exactly (case-sensitive)
2. Verify they're marked as **Protected**
3. Pipeline must be on `main` branch for protected variables
4. Try re-running pipeline: **CI/CD** → **Pipelines** → **Play** button

### "terraform init failed"

Variables likely not set correctly:

```bash
# In GitLab pipeline logs, check if credentials appear
# They should say [MASKED] if masked correctly
```

### Deployment timeout

Terraform operations may take 15-30 minutes for AKS cluster creation:

Update `.gitlab-ci.yml`:

```yaml
apply:
  timeout: 2 hours  # Increase timeout
```

## Next Steps

1. ✅ Create GitLab project
2. ✅ Mirror GitHub repo to GitLab
3. ✅ Set up Service Principal
4. ✅ Add CI/CD variables to GitLab
5. ✅ Verify pipeline runs on push
6. 🚀 Click apply to deploy AKS

## Rollback to GitHub (if needed)

```bash
# Remove GitLab remote
git remote remove origin

# Add GitHub back
git remote add origin https://github.com/vinupillai14/2026.git

# Verify
git remote -v
```

## Support

- GitLab docs: https://docs.gitlab.com/
- Check pipeline logs: **CI/CD** → **Pipelines** → Click job name
- Check variables: **Settings** → **CI/CD** → **Variables** (ensure all 4 are set)
- Terraform errors appear in `apply` job logs

---

**Quick Summary**:
```bash
# 1. Mirror repo
git clone --mirror https://github.com/vinupillai14/2026.git
cd 2026.git
git push --mirror https://TOKEN@gitlab.com/your-username/2026.git

# 2. Create Service Principal (in terminal)
az ad sp create-for-rbac --name "gitlab-terraform-2026" ...

# 3. Add variables to GitLab Settings → CI/CD → Variables

# 4. Test - make a commit
git push

# 5. Deploy - click Play on apply job
```

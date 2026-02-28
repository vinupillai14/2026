#!/bin/bash
# Bootstrap script to create Terraform backend in Azure
# Run this ONCE before deploying dev/preprod environments

set -e

echo "🔐 Creating Terraform State Backend in Azure..."
echo ""

# Check environment variables
if [ -z "$ARM_CLIENT_ID" ] || [ -z "$ARM_CLIENT_SECRET" ] || [ -z "$ARM_SUBSCRIPTION_ID" ] || [ -z "$ARM_TENANT_ID" ]; then
  echo "❌ Error: ARM credentials not set. Please set:"
  echo "   export ARM_CLIENT_ID=<your_client_id>"
  echo "   export ARM_CLIENT_SECRET=<your_client_secret>"
  echo "   export ARM_SUBSCRIPTION_ID=<your_subscription_id>"
  echo "   export ARM_TENANT_ID=<your_tenant_id>"
  exit 1
fi

# Check if backend storage account already exists
echo "🔍 Checking if backend storage account already exists..."
if az storage account show --name tfstateacct001 --resource-group rg-terraform-backend &>/dev/null 2>&1; then
  echo "✅ Backend storage account already exists!"
  echo ""
  echo "📝 Backend Configuration:"
  echo "   Storage Account: tfstateacct001"
  echo "   Container: tfstate"
  echo "   Resource Group: rg-terraform-backend"
  echo ""
  echo "The following state files are being used:"
  echo "   - dev.tfstate (dev environment)"
  echo "   - preprod.tfstate (preprod environment)"
  echo ""
  echo "Bootstrap has already completed. No action needed."
  exit 0
fi

# Navigate to bootstrap directory
cd "$(dirname "$0")/DevOps/terraform/bootstrap"

# Initialize and apply
echo "📦 Initializing bootstrap Terraform..."
terraform init

echo ""
echo "📊 Planning backend creation..."
terraform plan -out=bootstrap.tfplan

echo ""
echo "🚀 Creating backend storage account..."
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  terraform apply bootstrap.tfplan
  echo ""
  echo "✅ Backend creation complete!"
  echo ""
  echo "📝 Backend Configuration:"
  echo "   Storage Account: tfstateacct001"
  echo "   Container: tfstate"
  echo "   Resource Group: rg-terraform-backend"
  echo ""
  echo "The following state files will be stored:"
  echo "   - dev.tfstate (dev environment)"
  echo "   - preprod.tfstate (preprod environment)"
else
  echo "❌ Setup cancelled"
  exit 1
fi

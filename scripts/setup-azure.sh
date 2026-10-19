#!/usr/bin/env bash
# One-time Azure setup for the GitHub Actions -> Terraform -> ADF pipeline.
# Run in Azure Cloud Shell. Safe to re-run: existing resources produce a harmless error or no-op.
set -u

SUB_ID="64e08ab2-3ae0-4176-ba12-0e7316f43c1e"
IDENTITY_RG="rg-github-identity"
IDENTITY_NAME="github-terraform-identity"
IDENTITY_PRINCIPAL_ID="d93d771a-9967-4205-81d5-cf1e0670ec2b"
STATE_RG="rg-terraform-state"
STATE_STORAGE="sttfstatevenkata2026"   # must be globally unique
LOCATION="westus"
OWNER_REPO_SUBJECT="repo:BhavanaUppala97@228228616/service_creation@1420954693"

echo "== Register resource providers =="
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.DataFactory
for ns in Microsoft.Storage Microsoft.DataFactory; do
  until [ "$(az provider show --namespace $ns --query registrationState -o tsv)" = "Registered" ]; do
    echo "Waiting for $ns ..."; sleep 10
  done
done

echo "== Federated credentials =="
az identity federated-credential create --name github-main \
  --identity-name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" \
  --issuer https://token.actions.githubusercontent.com \
  --subject "$OWNER_REPO_SUBJECT:ref:refs/heads/main" \
  --audiences api://AzureADTokenExchange

az identity federated-credential create --name github-adf-dev-approval \
  --identity-name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" \
  --issuer https://token.actions.githubusercontent.com \
  --subject "$OWNER_REPO_SUBJECT:environment:adf-dev-approval" \
  --audiences api://AzureADTokenExchange

echo "== Terraform state storage =="
az group create --name "$STATE_RG" --location "$LOCATION"
az storage account create --name "$STATE_STORAGE" --resource-group "$STATE_RG" \
  --location "$LOCATION" --sku Standard_LRS --min-tls-version TLS1_2 \
  --allow-blob-public-access false
az storage container create --name tfstate --account-name "$STATE_STORAGE" --auth-mode key

echo "== Role assignments for the managed identity =="
for role in "Contributor" "User Access Administrator"; do
  az role assignment create --assignee-object-id "$IDENTITY_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal --role "$role" \
    --scope "/subscriptions/$SUB_ID"
done
az role assignment create --assignee-object-id "$IDENTITY_PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUB_ID/resourceGroups/$STATE_RG"

echo "Done. Set the GitHub variables listed in README.md."

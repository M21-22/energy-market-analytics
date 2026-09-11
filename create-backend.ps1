param(
    [string]$ResourceGroup = "rg-terraform-backend",
    [string]$StorageAccount = "tfstatebackend123",
    [string]$Container = "tfstate",
    [string]$Location = "northeurope"
)

az group create `
    --name $ResourceGroup `
    --location $Location

az storage account create `
    --name $StorageAccount `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS

az storage container create `
    --name $Container `
    --account-name $StorageAccount `
    --auth-mode login
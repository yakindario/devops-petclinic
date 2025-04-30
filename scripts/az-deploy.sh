#!/bin/bash

# Variables (establece valores reales)
RESOURCE_GROUP="petclinic-rg"
LOCATION="eastus"
AKS_NAME="petclinic-aks"
ACR_NAME="petclinicacr$(date +%s | head -c 5)" # Nombre único
ACR_SKU="Basic"

# Login to Azure
az login

# Create Resource Group
echo "Creando grupo de recursos $RESOURCE_GROUP..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
echo "Creando registro de contenedores $ACR_NAME..."
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku $ACR_SKU --admin-enabled true

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

# Create Azure Kubernetes Service
echo "Creando cluster de AKS $AKS_NAME..."
az aks create --resource-group $RESOURCE_GROUP --name $AKS_NAME --node-count 2 --enable-addons monitoring --generate-ssh-keys

# Connect ACR with AKS
echo "Conectando ACR con AKS..."
az aks update --name $AKS_NAME --resource-group $RESOURCE_GROUP --attach-acr $ACR_NAME

# Get AKS credentials
echo "Obteniendo credenciales de AKS..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

# Create Kubernetes secret for ACR
echo "Creando secreto para acceder al registro de contenedores..."
kubectl create secret docker-registry acr-secret \
  --docker-server=$ACR_NAME.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD

echo "Despliegue en Azure completado."
echo "Registro de contenedores: $ACR_NAME.azurecr.io"
echo "Clúster de Kubernetes: $AKS_NAME"
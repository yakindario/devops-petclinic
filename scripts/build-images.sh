#!/bin/bash

# Obtener el nombre del registro desde el primer argumento o usar el de az-deploy.sh
if [ -z "$1" ]; then
    # Intenta obtener el nombre del ACR creado
    REGISTRY_NAME=$(az acr list --query "[0].name" -o tsv)
    
    if [ -z "$REGISTRY_NAME" ]; then
        echo "Error: No se pudo determinar el nombre del registro de contenedores."
        echo "Uso: $0 <nombre_registro>"
        exit 1
    fi
else
    REGISTRY_NAME=$1
fi

IMAGE_NAME="petclinic"
TAG="latest"

# Asegúrate de que el usuario esté autenticado con ACR
echo "Iniciando sesión en el registro de contenedores..."
az acr login --name $REGISTRY_NAME

# Determinar la ruta base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Comprueba si existe un Dockerfile, si no, crea uno de ejemplo
if [ ! -f "$PROJECT_ROOT/Dockerfile" ]; then
    echo "No se encontró un Dockerfile."
    echo "Por favor, asegúrate de tener la aplicación compilada."
    exit 1
fi

# Build Docker images
echo "Construyendo imagen Docker..."
docker build -t $REGISTRY_NAME.azurecr.io/$IMAGE_NAME:$TAG -f "$PROJECT_ROOT/Dockerfile" "$PROJECT_ROOT"

# Push the image to Azure Container Registry
echo "Enviando imagen a Azure Container Registry..."
docker push $REGISTRY_NAME.azurecr.io/$IMAGE_NAME:$TAG

echo "Imagen Docker construida y enviada con éxito: $REGISTRY_NAME.azurecr.io/$IMAGE_NAME:$TAG"

# Actualiza los archivos de despliegue para usar esta imagen
# Actualiza los archivos de despliegue con la configuración de imagePullSecret
echo "Actualizando configuración de imagePullSecret en deployment.yaml..."
if ! sed -i "s|<your-image-pull-secret>|acr-secret|g" "$PROJECT_ROOT/kubernetes/base/deployment.yaml"; then
    echo "Error: No se pudo actualizar el imagePullSecret en deployment.yaml"
    exit 1
fi

# Verificar que el cambio se realizó correctamente
if ! grep -q "acr-secret" "$PROJECT_ROOT/kubernetes/base/deployment.yaml"; then
    echo "Error: No se encontró 'acr-secret' en el archivo deployment.yaml después de la actualización"
    echo "Verifique que el archivo contiene el placeholder <your-image-pull-secret>"
    exit 1
fi

echo "✅ Configuración de imagePullSecret actualizada correctamente"
echo "Proceso completado."
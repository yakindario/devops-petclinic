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

# Comprueba si existe un Dockerfile, si no, crea uno de ejemplo
if [ ! -f "../Dockerfile" ]; then
    echo "No se encontró un Dockerfile. Creando uno de ejemplo..."
    cat > ../Dockerfile << EOF
FROM openjdk:11-jre-slim
WORKDIR /app
COPY ./target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
EOF
    echo "Dockerfile de ejemplo creado. Por favor, asegúrate de tener la aplicación compilada."
fi

# Build Docker images
echo "Construyendo imagen Docker..."
docker build -t $REGISTRY_NAME.azurecr.io/$IMAGE_NAME:$TAG -f ../Dockerfile ..

# Push the image to Azure Container Registry
echo "Enviando imagen a Azure Container Registry..."
docker push $REGISTRY_NAME.azurecr.io/$IMAGE_NAME:$TAG

echo "Imagen Docker construida y enviada con éxito: $REGISTRY_NAME.azurecr.io/$IMAGE_NAME:$TAG"

# Actualiza los archivos de despliegue para usar esta imagen
echo "Actualizando archivos de despliegue con la nueva imagen..."
sed -i "s|<your-container-registry>/petclinic:latest|$REGISTRY_NAME.azurecr.io/$IMAGE_NAME:$TAG|g" ../kubernetes/base/deployment.yaml
sed -i "s|<your-image-pull-secret>|acr-secret|g" ../kubernetes/base/deployment.yaml

echo "Proceso completado."
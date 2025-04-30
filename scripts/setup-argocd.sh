#!/bin/bash

# Variables
ARGOCD_VERSION="stable"
NAMESPACE_ARGOCD="argocd"

# Crear namespaces necesarios
echo "Creando namespaces necesarios..."
kubectl create namespace $NAMESPACE_ARGOCD
kubectl create namespace petclinic
kubectl create namespace monitoring
kubectl create namespace telemetry

# Instalar ArgoCD
echo "Instalando ArgoCD..."
kubectl apply -n $NAMESPACE_ARGOCD -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml

# Esperar a que los pods de ArgoCD estén listos
echo "Esperando a que los pods de ArgoCD estén listos..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n $NAMESPACE_ARGOCD --timeout=300s

# Exponer el servidor de ArgoCD
echo "Exponiendo el servidor de ArgoCD..."
kubectl patch svc argocd-server -n $NAMESPACE_ARGOCD -p '{"spec": {"type": "LoadBalancer"}}'

# Esperar a que se asigne una IP externa
echo "Esperando a que se asigne una IP externa al servicio de ArgoCD..."
while [ -z "$(kubectl get svc argocd-server -n $NAMESPACE_ARGOCD -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)" ]; do
    echo "Esperando IP externa..."
    sleep 10
done

# Obtener la información de acceso
ARGOCD_SERVER=$(kubectl get svc argocd-server -n $NAMESPACE_ARGOCD -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
ARGOCD_PASSWORD=$(kubectl -n $NAMESPACE_ARGOCD get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "Aplicando manifiestos de ArgoCD..."

# Determinar la ruta base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGO_MANIFESTS_DIR="$PROJECT_ROOT/argo-manifests"

# Verificar la versión de ArgoCD instalada en el clúster
echo "Verificando versión de ArgoCD instalada..."
ARGOCD_INSTALLED_VERSION=$(kubectl -n $NAMESPACE_ARGOCD get deployment argocd-server -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d: -f2)
echo "Versión de ArgoCD instalada: $ARGOCD_INSTALLED_VERSION"

# Obtener la URL del repositorio Git
REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
if [ -z "$REPO_URL" ]; then
    echo "Advertencia: No se pudo determinar la URL del repositorio Git."
    read -p "Ingrese la URL del repositorio (https://github.com/usuario/repo): " REPO_URL
    if [ -z "$REPO_URL" ]; then
        echo "Error: Se requiere una URL de repositorio válida para continuar."
        exit 1
    fi
else
    # Normalizar la URL del repositorio
    REPO_URL=$(echo "$REPO_URL" | sed 's|git@github.com:|https://github.com/|')
fi

# Respaldo del archivo de aplicación original
cp "$ARGO_MANIFESTS_DIR/application.yaml" "$ARGO_MANIFESTS_DIR/application.yaml.bak"

# Actualizar la URL del repositorio en el manifiesto de la aplicación
echo "Configurando aplicación de ArgoCD con repositorio: $REPO_URL"
if ! sed -i "s|https://github.com/your-repo/petclinic.git|$REPO_URL|g" "$ARGO_MANIFESTS_DIR/application.yaml"; then
    echo "Error: No se pudo actualizar la URL del repositorio en application.yaml"
    mv "$ARGO_MANIFESTS_DIR/application.yaml.bak" "$ARGO_MANIFESTS_DIR/application.yaml"
    exit 1
fi

# Actualizar el archivo application.yaml para compatibilidad con la versión instalada
echo "Adaptando manifiesto de aplicación para la versión instalada de ArgoCD..."
if [[ "$ARGOCD_INSTALLED_VERSION" == "v"* ]]; then
    # Eliminar los campos no compatibles según la versión detectada
    if ! sed -i '/syncWindow/d' "$ARGO_MANIFESTS_DIR/application.yaml" || \
       ! sed -i '/helm:/,/valueFiles:/d' "$ARGO_MANIFESTS_DIR/application.yaml"; then
        echo "Error: No se pudieron eliminar campos incompatibles del application.yaml"
        echo "Restaurando archivo original..."
        mv "$ARGO_MANIFESTS_DIR/application.yaml.bak" "$ARGO_MANIFESTS_DIR/application.yaml"
        exit 1
    fi
    
    # Asegurarse de que la estructura sigue siendo válida después de eliminar secciones
    echo "Verificando estructura del archivo YAML..."
    if ! kubectl apply -f "$ARGO_MANIFESTS_DIR/application.yaml" --dry-run=client; then
        echo "Error: El archivo application.yaml modificado no es válido"
        echo "Restaurando archivo original..."
        mv "$ARGO_MANIFESTS_DIR/application.yaml.bak" "$ARGO_MANIFESTS_DIR/application.yaml"
        exit 1
    fi
fi

# Verificar que el cambio se realizó correctamente
if ! grep -q "$REPO_URL" "$ARGO_MANIFESTS_DIR/application.yaml"; then
    echo "Error: No se pudo verificar la actualización de la URL del repositorio"
    mv "$ARGO_MANIFESTS_DIR/application.yaml.bak" "$ARGO_MANIFESTS_DIR/application.yaml"
    exit 1
fi

# Aplicar el manifiesto de la aplicación (una sola vez)
echo "Desplegando aplicación en ArgoCD..."
if ! kubectl apply -f "$ARGO_MANIFESTS_DIR/application.yaml"; then
    echo "Error: No se pudo aplicar el archivo application.yaml"
    echo "Restaurando archivo original..."
    mv "$ARGO_MANIFESTS_DIR/application.yaml.bak" "$ARGO_MANIFESTS_DIR/application.yaml"
    exit 1
fi

# Limpiar archivo de respaldo
rm -f "$ARGO_MANIFESTS_DIR/application.yaml.bak"

echo "✅ Manifiestos de ArgoCD aplicados correctamente"
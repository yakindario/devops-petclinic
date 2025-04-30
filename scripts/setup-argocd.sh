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

# Aplicar los manifiestos de aplicación y proyecto de ArgoCD
echo "Aplicando manifiestos de ArgoCD..."
kubectl apply -f ../argo-manifests/project.yaml
sed -i "s|https://github.com/your-repo/petclinic.git|https://github.com/$(git config --get remote.origin.url | sed 's|https://github.com/||' 2>/dev/null || echo "your-repo/petclinic.git")|g" ../argo-manifests/application.yaml
kubectl apply -f ../argo-manifests/application.yaml

# Mostrar información de acceso
echo "==================================================================="
echo "ArgoCD instalado en el namespace '$NAMESPACE_ARGOCD'."
echo "Accede a ArgoCD en: http://$ARGOCD_SERVER"
echo "Usuario: admin"
echo "Contraseña: $ARGOCD_PASSWORD"
echo "==================================================================="
echo "Guarda esta información en un lugar seguro."
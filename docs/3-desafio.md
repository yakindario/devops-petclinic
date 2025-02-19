# Desafío Final: Modernización y Automatización de petclinic

![](./images/4.png)

## Descripción del Desafío
Implementar una versión modernizada de petclinic con automatización completa, observabilidad y mejores prácticas DevOps.

## Objetivos Principales
1. Implementar pipeline CI/CD completo
2. Establecer observabilidad end-to-end
3. Automatizar el despliegue y la infraestructura
4. Implementar mejores prácticas de seguridad
5. Configurar monitoreo y alertas

## Requerimientos del Proyecto

### 1. Infraestructura como Código
- Crear módulos Terraform para:
  - Infraestructura base (VPC, subredes, etc.)
  - Servicios de bases de datos (MySQL, DynamoDB, Redis)
  - Clúster Kubernetes
  - Sistemas de monitoreo

### 2. Pipeline CI/CD
Implementar con GitHub Actions ó Gitlab:
- Build y test automatizados
- Escaneo de seguridad (SAST)
- Construcción y push de imágenes Docker
- Despliegue automatizado a diferentes ambientes
- Notificaciones de estado

### 3. Observabilidad
Configurar stack de monitoreo:
- Prometheus para métricas
- Grafana para visualización
- Loki para logs
- Tempo para trazas
- Dashboards predefinidos para:
  - Métricas de aplicación
  - Métricas de infraestructura

### 4. Kubernetes y GitOps
- Crear Helm charts para todos los servicios
- Implementar ArgoCD para GitOps
- Configurar:
  - Límites de recursos
  - Health checks
  - Auto-scaling

### 5. Seguridad
- Implementar:
  - Escaneo de vulnerabilidades
  - Gestión de secretos

## Entregables Requeridos

### 1. Repositorio de Código
```
petclinic/
├── terraform/                  # IaC
│   ├── modules/
│   └── environments/
├── kubernetes/                 # Manifiestos K8s
│   ├── helm-charts/
│   └── argocd/
├── monitoring/                # Configuración observabilidad
│   ├── prometheus/
│   ├── grafana/
│   └── loki/
├── ci-cd/                     # Pipelines
│   └── .github/workflows/
└── docs/                      # Documentación
```

### 2. Documentación Técnica
- Arquitectura del sistema
- Guía de despliegue
- Procedimientos operativos
- Runbooks de incidentes
- Diagramas de arquitectura

### 3. Implementación Funcional
- Pipeline CI/CD operativo
- Stack de observabilidad funcionando
- Aplicación desplegada en Kubernetes
- Dashboards de monitoreo

## Criterios de Evaluación

### 1. Automatización 
- Pipeline CI/CD funcional
- Despliegue automatizado
- Gestión de configuración
- Scripts de automatización

### 2. Observabilidad 
- Métricas recolectadas
- Logs centralizados
- Trazas distribuidas
- Dashboards informativos
- Alertas configuradas

### 3. Seguridad 
- Escaneo de vulnerabilidades
- Gestión de secretos

### 4. Documentación 
- Claridad y completitud
- Diagramas y arquitectura
- Procedimientos operativos
- Guías de troubleshooting

### 5. Presentación 
- Demo funcional (video)
- Claridad de explicación
- Dominio del tema

## Metodología de Trabajo
1. Planning inicial con definición de arquitectura
2. Desarrollo iterativo con checkpoints semanales
3. Testing continuo
4. Documentación incremental
5. Presentación demo

## Requisitos Técnicos
- Cuenta AWS/Azure/Gcp/DigitalOcean/Minikube
- GitHub/GitLab cuenta
- Herramientas locales:
  - Docker
  - kubectl
  - terraform
  - helm
  - argocd CLI


## Bonus Points 
- Implementación de Chaos Engineering
- Optimización de costos (FinOps)
- Integración de ML/AI
- Alta disponibilidad probada
- Métricas DORA implementadas
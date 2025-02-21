# Como desplegar de forma local

### Punto de Partida 
El sistema está dividido en dos componentes principales definidos en archivos Docker Compose separados:
- `compose.yml`: Servicios principales del negocio
- `compose.monitor.yml`: Stack de observabilidad y monitoreo

> Estos son puntos de partida referenciales para resolver el desafío

```
git clone https://gitlab.com/training-devops-cf/cf-devops-challenge/cf-devops-petclinic.git
cd cf-devops-petclinic
./mvnw package
java -jar target/*.jar
```

Luego puedes acceder a petclinic aquí: http://localhost:8080/

<img width="625" alt="image" src="https://user-images.githubusercontent.com/313480/179161406-54a28200-d52e-411f-bfbe-463cf64b64b3.png">

La aplicación te permite realizar las siguientes funciones:

- Agregar Mascotas
- Agregar Dueños
- Encontrar Dueños
- Encontrar Veterinarios
- Manejo de Excepciones

O puedes ejecutarlo directamente desde Maven usando el plugin de Spring Boot para Maven. Si haces esto, recogerá los cambios que realices en el proyecto inmediatamente (los cambios en los archivos fuente de Java también requieren una compilación - la mayoría de las personas usan un IDE para esto):

```
./mvnw spring-boot:run
```

### Servicios de Negocio (compose.yml)

#### Bussiness Layer
1. **PetClinic Service**
   - Puerto: 8080:8080
   - Tecnología: Java (Spring Boot)
   - Función: Interfaz de usuario principal
   - Base de datos: Mysql

### Stack de Observabilidad (compose.monitor.yml)

#### Recolección y Procesamiento
1. **OpenTelemetry Collector**
   - Puertos: 13133, 8888, 8889
   - Función: Recolección centralizada de telemetría

#### Almacenamiento y Análisis
1. **Prometheus**
   - Puerto: 9090
   - Función: Almacenamiento y consulta de métricas
   - Configuración: 
     - Archivo de reglas
     - Soporte OTLP

2. **Jaeger**
   - Puertos: 4317, 9411, 16686
   - Función: Análisis de trazas distribuidas

## Configuración de Observabilidad

### Exportación de Telemetría
Todos los servicios están configurados con las siguientes variables de entorno para exportar telemetría:
```yaml
- OTEL_TRACES_EXPORTER=otlp
- OTEL_METRICS_EXPORTER=prometheus
- OTEL_EXPORTER_OTLP_ENDPOINT=http://otel:4317
- OTEL_SERVICE_NAME=<service>-service
- OTEL_RESOURCE_ATTRIBUTES=service.name=<service>-service

### Persistencia de Datos
Volúmenes configurados para persistencia:
- log-data
- prometheus-data


# Guía de Despliegue Entorno LOCAL

### Prerrequisitos
- Docker y Docker Compose instalados
- Mínimo 8GB de RAM disponible
- 20GB de espacio en disco

### Docker Compose
1. Desplegar stack de observabilidad:

   ```bash
   docker compose -f compose.monitor.yml up -d
   ```

2. Desplegar servicios de negocio:
   ```bash
   docker compose -f compose.yml up -d --build
   ```


### Verificación del Despliegue
1. UI: http://localhost:8080
2. Prometheus: http://localhost:9090
3. Jaeger UI: http://localhost:16686

## Mantenimiento y Monitoreo

### Endpoints de Salud
- OpenTelemetry Collector: http://localhost:13133


### Dashboards Recomendados
1. **Overview del Sistema**
   - Métricas de servicios
   - Tasas de error
   - Latencia de endpoints

2. **Monitoreo de Bases de Datos**
   - Conexiones activas
   - Tiempos de consulta
   - Uso de recursos

3. **Trazas de Transacciones**
   - Flujo de checkout
   - Procesamiento de órdenes
   - Latencia end-to-end

### Clean

   ```bash
   docker compose -f compose.monitor.yml down -v
   ```

2. Desplegar servicios de negocio:
   ```bash
   docker compose -f compose.yml down
   ```


## Referencias

- [Construyendo la aplicación PetClinic usando Dockerfile](https://docs.docker.com/language/java/build-images/)

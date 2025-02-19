#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuración
HOST="localhost"
PORT="8080"
BASE_URL="http://$HOST:$PORT"
CONCURRENT_USERS=50
NUM_REQUESTS=500
RESULTS_DIR="benchmark_results"

# Detectar sistema operativo
OS="$(uname)"

# Crear directorio para resultados
mkdir -p "$RESULTS_DIR"

# Función para imprimir mensajes formateados
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar si el servicio está disponible
check_service() {
    log "Verificando si PetClinic está disponible..."
    if curl -s "$BASE_URL" | grep -q "PetClinic"; then
        log "PetClinic está funcionando correctamente"
        return 0
    else
        error "PetClinic no está disponible"
        return 1
    fi
}

# Función para obtener uso de CPU y memoria según el sistema operativo
get_system_stats() {
    if [ "$OS" = "Darwin" ]; then
        # macOS
        echo "=== $(date) ==="
        echo "CPU Usage:"
        top -l 1 -n 0 | grep "CPU usage"
        echo "Memory Usage:"
        vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^0-9]+(\d+)/ and printf("%-16s % 16.2f Mi\n", "$1:", $2 * $size / 1048576)'
    else
        # Linux
        echo "=== $(date) ==="
        echo "CPU Usage:"
        top -bn1 | head -20
        echo "Memory Usage:"
        free -m
    fi
}

# Función para probar un endpoint
benchmark_endpoint() {
    local endpoint=$1
    local description=$2
    local output_file="$RESULTS_DIR/$(echo $endpoint | sed 's/\//_/g' | sed 's/?/_/g').txt"
    
    log "Probando $description ($endpoint)"
    
    # Verificar si ab está instalado
    if ! command -v ab &> /dev/null; then
        error "Apache Benchmark (ab) no está instalado. Por favor, instálalo para continuar."
        if [ "$OS" = "Darwin" ]; then
            echo "En macOS puedes instalarlo con: brew install apr-util"
        else
            echo "En Linux puedes instalarlo con: sudo apt-get install apache2-utils"
        fi
        exit 1
    fi
    
    ab -n $NUM_REQUESTS -c $CONCURRENT_USERS -k "$BASE_URL$endpoint" > "$output_file" 2>&1
    
    # Extraer métricas relevantes
    local rps=$(grep "Requests per second" "$output_file" | awk '{print $4}')
    local mean_time=$(grep "Time per request" "$output_file" | head -1 | awk '{print $4}')
    local p95=$(grep "95%" "$output_file" | awk '{print $2}')
    
    echo -e "${YELLOW}Resultados para $description:${NC}"
    echo "  - Requests por segundo: $rps"
    echo "  - Tiempo medio por request: $mean_time ms"
    echo "  - P95: $p95 ms"
    echo ""
}

# Función para generar carga en endpoints específicos
generate_load() {
    log "Iniciando pruebas de carga..."
    
    # Lista de endpoints a probar (formato: "endpoint:descripción")
    ENDPOINTS=(
        "/:Página principal"
        "/vets.html:Lista de veterinarios"
        "/owners/find:Búsqueda de propietarios"
        "/owners?lastName=:Búsqueda de propietarios vacía"
        "/owners/1:Detalles de propietario"
        "/owners/1/edit:Edición de propietario"
    )
    
    # Probar cada endpoint
    for endpoint_pair in "${ENDPOINTS[@]}"; do
        IFS=":" read -r endpoint description <<< "$endpoint_pair"
        benchmark_endpoint "$endpoint" "$description"
    done
}

# Función para probar tiempos de respuesta individuales
test_response_times() {
    log "Probando tiempos de respuesta individuales..."
    local output_file="$RESULTS_DIR/curl_timings.txt"
    
    # Formato de curl para tiempos
    FORMAT="\n%{url_effective} -> DNS: %{time_namelookup}s - Connect: %{time_connect}s - TotalTime: %{time_total}s - ResponseCode: %{http_code}\n"
    
    ENDPOINTS=(
        "/"
        "/vets.html"
        "/owners/find"
        "/owners/1"
    )
    
    for endpoint in "${ENDPOINTS[@]}"; do
        curl -w "$FORMAT" -o /dev/null -s "$BASE_URL$endpoint" >> "$output_file"
        sleep 1  # Pequeña pausa entre requests
    done
    
    log "Resultados guardados en $output_file"
}

# Función para monitorear recursos del sistema
monitor_resources() {
    log "Iniciando monitoreo de recursos..."
    local pid=$1
    local output_file="$RESULTS_DIR/resource_usage.txt"
    
    while kill -0 $pid 2>/dev/null; do
        get_system_stats >> "$output_file"
        echo "====================" >> "$output_file"
        sleep 5
    done
}

# Función para crear reporte
generate_report() {
    log "Generando reporte final..."
    local report_file="$RESULTS_DIR/benchmark_report.md"
    
    # Crear encabezado del reporte
    cat << EOF > "$report_file"
# PetClinic Benchmark Report
Fecha: $(date)
Host: $BASE_URL
Sistema Operativo: $OS
Usuarios Concurrentes: $CONCURRENT_USERS
Requests Totales: $NUM_REQUESTS

## Resultados por Endpoint
EOF
    
    # Agregar resultados de cada endpoint
    for file in "$RESULTS_DIR"/*.txt; do
        if [[ $file == *"curl"* ]] || [[ $file == *"resource"* ]] || [[ $file == *"report"* ]]; then
            continue
        fi
        
        echo -e "\n### $(basename "$file" .txt)" >> "$report_file"
        echo '```' >> "$report_file"
        grep -A 4 "Requests per second" "$file" >> "$report_file"
        echo '```' >> "$report_file"
    done
    
    # Agregar resultados de curl
    echo -e "\n## Tiempos de Respuesta Individuales" >> "$report_file"
    echo '```' >> "$report_file"
    cat "$RESULTS_DIR/curl_timings.txt" >> "$report_file"
    echo '```' >> "$report_file"
    
    log "Reporte generado en $report_file"
}

# Función para limpiar recursos
cleanup() {
    log "Limpiando recursos..."
    # Detener procesos en segundo plano
    jobs -p | xargs -r kill 2>/dev/null || jobs -p | xargs kill 2>/dev/null
}

# Registrar función de limpieza
trap cleanup EXIT

# Función principal
main() {
    log "Iniciando benchmark de Spring PetClinic"
    
    # Verificar que el servicio esté disponible
    check_service || exit 1
    
    # Iniciar monitoreo de recursos en segundo plano
    monitor_resources $$ &
    
    # Ejecutar pruebas
    generate_load
    test_response_times
    
    # Generar reporte
    generate_report
    
    log "Benchmark completado. Revisa los resultados en $RESULTS_DIR"
}

# Ejecutar script
main "$@"
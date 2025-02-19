import http from 'k6/http';
import { sleep, check } from 'k6';
import { Counter } from 'k6/metrics';
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.1/index.js";


// Configuración de la prueba
export const options = {
    stages: [
        { duration: '10s', target: 50 }, // Rampa de subida hasta 500 usuarios en 10s
        { duration: '1m', target: 50 },  // Mantener 500 usuarios durante 1 minuto
        { duration: '10s', target: 0 }    // Rampa de bajada
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% de las peticiones deben completarse en menos de 500ms
        'http_req_duration{staticAsset:yes}': ['p(95)<100'], // Assets estáticos más rápidos
    },
};

// Variables globales
const PETCLINIC_HOST = __ENV.PETCLINIC_HOST || 'http://localhost:8080';
const CONTEXT_WEB = __ENV.CONTEXT_WEB || '';

// Contadores personalizados
const pageSuccessRate = new Counter('page_success_rate');

// Función para generar números aleatorios entre min y max
function randomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

export default function() {
    const ownerId = randomInt(1, 10);
    const petId = randomInt(1, 13);

    // Grupo 1: Página principal y recursos estáticos
    {
        // Homepage
        let res = http.get(`${PETCLINIC_HOST}${CONTEXT_WEB}/`);
        check(res, {
            'homepage status 200': (r) => r.status === 200,
        }) && pageSuccessRate.add(1);

        // Recursos estáticos
        http.get(`${PETCLINIC_HOST}${CONTEXT_WEB}/resources/css/petclinic.css`, {
            tags: { staticAsset: 'yes' }
        });
        http.get(`${PETCLINIC_HOST}${CONTEXT_WEB}/webjars/jquery/jquery.min.js`, {
            tags: { staticAsset: 'yes' }
        });
    }

    sleep(0.3); // 300ms de espera como en JMeter

    // Grupo 2: Veterinarios
    {
        let res = http.get(`${PETCLINIC_HOST}${CONTEXT_WEB}/vets.html`);
        check(res, {
            'vets page status 200': (r) => r.status === 200,
        }) && pageSuccessRate.add(1);
    }

    // Grupo 3: Búsqueda de propietarios
    {
        let res = http.get(`${PETCLINIC_HOST}${CONTEXT_WEB}/owners/find`);
        check(res, {
            'find owners page status 200': (r) => r.status === 200,
        }) && pageSuccessRate.add(1);

        res = http.get(`${PETCLINIC_HOST}${CONTEXT_WEB}/owners?lastName=`);
        check(res, {
            'search owners status 200': (r) => r.status === 200,
        }) && pageSuccessRate.add(1);
    }

    // Grupo 4: Detalles y edición de propietario
    {
        let res = http.get(`${PETCLINIC_HOST}${CONTEXT_WEB}/owners/${ownerId}`);
        check(res, {
            'owner details status 200': (r) => r.status === 200,
        }) && pageSuccessRate.add(1);

        // Formulario de edición
        res = http.get(`${PETCLINIC_HOST}${CONTEXT_WEB}/owners/${ownerId}/edit`);
        check(res, {
            'edit owner form status 200': (r) => r.status === 200,
        }) && pageSuccessRate.add(1);

        // Envío del formulario de edición
        res = http.post(`${PETCLINIC_HOST}${CONTEXT_WEB}/owners/${ownerId}/edit`, {
            firstName: 'Test',
            lastName: `${ownerId}`,
            address: '1234 Test St.',
            city: 'TestCity',
            telephone: '612345678'
        });
        check(res, {
            'edit owner submit status 200': (r) => r.status === 200,
        }) && pageSuccessRate.add(1);
    }

    // Grupo 5: Gestión de visitas
    {
        // Nueva visita
        let res = http.get(`${PETCLINIC_HOST}${CONTEXT_WEB}/owners/${ownerId}/pets/${petId}/visits/new`);
        check(res, {
            'new visit form status 200': (r) => r.status === 200,
        }) && pageSuccessRate.add(1);

        // Crear visita
        res = http.post(`${PETCLINIC_HOST}${CONTEXT_WEB}/owners/${ownerId}/pets/${petId}/visits/new`, {
            date: '2025/02/22',
            description: 'visit'
        });
        check(res, {
            'create visit status 200': (r) => r.status === 200,
        }) && pageSuccessRate.add(1);
    }

    // Verificación final del propietario
    {
        let res = http.get(`${PETCLINIC_HOST}${CONTEXT_WEB}/owners/${ownerId}`);
        check(res, {
            'final owner check status 200': (r) => r.status === 200,
        }) && pageSuccessRate.add(1);
    }

    sleep(0.3); // Pausa final
}

export function handleSummary(data) {
    return {
        "results.html": htmlReport(data, {
            title: 'Spring PetClinic Performance Test',
            descriptions: {
                pageSuccessRate: 'Tasa de éxito de las páginas',
                http_req_duration: 'Duración de las peticiones HTTP',
                'http_req_duration{staticAsset:yes}': 'Duración de las peticiones de recursos estáticos'
            }
        }),
        "results.json": JSON.stringify(data),
        stdout: textSummary(data, { indent: " ", enableColors: true })
    };
}
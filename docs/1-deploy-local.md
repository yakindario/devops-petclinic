## Empezando

```
git clone https://gitlab.com/cf-devops-petclinic.git
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

> NOTA: Los usuarios de Windows deben configurar `git config core.autocrlf true` para evitar que las afirmaciones de formato fallen en la compilación (usa `--global` para establecer esa bandera globalmente).

> NOTA: Si prefieres usar Gradle, puedes construir la aplicación usando `./gradlew build` y buscar el archivo jar en `build/libs`.


## Construcción 

```
 docker build -t petclinic-app . -f Dockerfile.multi
```

## Usando Docker Compose

```
 docker-compose up -d
```

## Referencias

- [Construyendo la aplicación PetClinic usando Dockerfile](https://docs.docker.com/language/java/build-images/)

FROM eclipse-temurin:21-jdk-jammy AS base
WORKDIR /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:resolve
COPY src ./src

# Instalar el agente OpenTelemetry en base para compartirlo
ARG OTEL_AGENT_VERSION=1.32.0
RUN curl -L https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar \
    -o /opt/opentelemetry-javaagent.jar

FROM base AS development
# Configura el agente OpenTelemetry y el debugger
ENV JAVA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
ENV JAVA_TOOL_OPTIONS="-javaagent:/opt/opentelemetry-javaagent.jar"
CMD ["./mvnw", "spring-boot:run", "-Dspring-boot.run.profiles=mysql"]

FROM base AS build
RUN ./mvnw package

FROM eclipse-temurin:21-jre-jammy AS production
EXPOSE 8080

# Copia el agente OpenTelemetry desde base
COPY --from=base /opt/opentelemetry-javaagent.jar /opt/opentelemetry-javaagent.jar

# Configura OpenTelemetry para producción
ENV JAVA_TOOL_OPTIONS="-javaagent:/opt/opentelemetry-javaagent.jar"

COPY --from=build /app/target/spring-petclinic-*.jar /spring-petclinic.jar
CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/spring-petclinic.jar"]
FROM eclipse-temurin:25.0.4_7-jre-alpine

RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /opt/app

COPY --chown=app:app target/*.jar ./application.jar

USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --proxy off --no-verbose --tries=1 --spider http://localhost:8080/health/liveness || exit 1

ENTRYPOINT ["java", "-jar", "application.jar"]

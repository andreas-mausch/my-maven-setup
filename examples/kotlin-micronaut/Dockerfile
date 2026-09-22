FROM alpine:3.24.2 AS artifact

WORKDIR /tmp/jars

COPY target/*.jar ./

RUN set -eu; \
  executable_jar=""; \
  for jar in *.jar; do \
    if unzip -l "$jar" io/micronaut/runtime/Micronaut.class 2>/dev/null \
        | grep -q 'io/micronaut/runtime/Micronaut.class'; then \
      test -z "$executable_jar" || { echo "Multiple application JARs found" >&2; exit 1; }; \
      executable_jar="$jar"; \
    fi; \
  done; \
  test -n "$executable_jar" || { echo "No application JAR found" >&2; exit 1; }; \
  cp "$executable_jar" application.jar

FROM eclipse-temurin:25.0.4_7-jre-alpine

RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /opt/app

COPY --from=artifact --chown=app:app /tmp/jars/application.jar ./application.jar

USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --proxy off --no-verbose --tries=1 --spider http://localhost:8080/health/liveness || exit 1

ENTRYPOINT ["java", "-jar", "application.jar"]

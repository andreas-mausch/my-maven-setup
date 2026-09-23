# Kotlin/Micronaut Project Setup

This guide covers how to use the `parent-kotlin-micronaut.xml` parent POM for Kotlin applications built with
Micronaut.

`kotlin-micronaut-parent` extends `kotlin-parent`. See [README-kotlin.md](README-kotlin.md) for the inherited Kotlin and
Java build configuration.

- [How to Use](#how-to-use)
- [Source Layout](#source-layout)
- [Application Entry Point](#application-entry-point)
- [Build and Run](#build-and-run)
  - [Build command](#build-command)
  - [Run locally](#run-locally)
  - [Shaded executable JAR](#shaded-executable-jar)
- [Micronaut Processing](#micronaut-processing)
- [Test Resources](#test-resources)
- [Shared Features](#shared-features)

# How to Use

Create a `pom.xml` in your project:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>de.neonew</groupId>
    <artifactId>kotlin-micronaut-parent</artifactId>
    <version>1.0.0</version>
    <relativePath />
  </parent>

  <groupId>com.example</groupId>
  <artifactId>my-app</artifactId>
  <version>1.0.0-SNAPSHOT</version>

  <properties>
    <main.class>com.example.ApplicationKt</main.class>
    <micronaut.application.package>com.example</micronaut.application.package>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.micronaut</groupId>
      <artifactId>micronaut-http-server-netty</artifactId>
    </dependency>
    <dependency>
      <groupId>io.micronaut.kotlin</groupId>
      <artifactId>micronaut-kotlin-runtime</artifactId>
    </dependency>
    <dependency>
      <groupId>io.micronaut.serde</groupId>
      <artifactId>micronaut-serde-jackson</artifactId>
    </dependency>
    <dependency>
      <groupId>org.jetbrains.kotlin</groupId>
      <artifactId>kotlin-reflect</artifactId>
    </dependency>
    <dependency>
      <groupId>org.jetbrains.kotlin</groupId>
      <artifactId>kotlin-stdlib</artifactId>
    </dependency>
    <dependency>
      <groupId>ch.qos.logback</groupId>
      <artifactId>logback-classic</artifactId>
      <scope>runtime</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>io.micronaut.maven</groupId>
        <artifactId>micronaut-maven-plugin</artifactId>
      </plugin>
      <plugin>
        <groupId>me.kpavlov.ksp.maven</groupId>
        <artifactId>ksp-maven-plugin</artifactId>
      </plugin>
      <plugin>
        <groupId>org.jetbrains.kotlin</groupId>
        <artifactId>kotlin-maven-plugin</artifactId>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
```

Configure GitHub Packages as described in [README.md](README.md#configure-github-packages) so Maven can resolve the
parent and its shared configuration artifacts.

The parent imports the Micronaut Platform BOM, so dependencies covered by the platform do not need explicit versions.
It also manages versions for KotlinLogging, MongoDB, Mongock, Awaitility, and WireMock. Dependencies are not added
automatically; consumers declare only the libraries they use.

A complete application using HTTP, MongoDB, RabbitMQ, Micronaut Data, JSON/BSON serialization, Testcontainers,
generated OpenAPI documentation, and RapiDoc is available in
[`examples/kotlin-micronaut/`](examples/kotlin-micronaut/).

# Source Layout

The parent uses the same Kotlin source layout as `kotlin-parent`:

```text
src/main/kotlin
src/main/resources
src/test/kotlin
src/test/resources
src/test-integration/kotlin
src/test-integration/resources
```

Kotlin and Java compilation target JVM 25. The parent does not configure mixed Java/Kotlin compilation.

# Application Entry Point

Create `src/main/kotlin/com/example/Application.kt`:

```kotlin
package com.example

import io.micronaut.runtime.Micronaut

fun main(args: Array<String>) {
  Micronaut.run(Application::class.java, *args)
}

object Application
```

The top-level `main` function compiles to `ApplicationKt`, matching the configured `main.class`. The
`micronaut.application.package` property identifies the application package for the inherited ProGuard rules.

# Build and Run

## Build command

```bash
mvn clean verify
```

This runs KSP, Kotlin compilation, unit tests, and JAR packaging. Enforcer checks and integration tests require the
consumer POM to activate the inherited `maven-enforcer-plugin`, `maven-failsafe-plugin`, and
`build-helper-maven-plugin` configurations. The complete
[`examples/kotlin-micronaut/pom.xml`](examples/kotlin-micronaut/pom.xml) demonstrates these declarations.

Integration tests belong under `src/test-integration/kotlin` and must use a package containing `.integration.`.
Surefire excludes these packages from unit-test runs, while Failsafe includes them during `verify`.

## Run locally

```bash
mvn mn:run
```

The Micronaut Maven plugin starts the application using the class configured through `main.class`.

## Shaded executable JAR

The `maven-shade-plugin` declaration activates the inherited executable-JAR configuration. Build and run it with:

```bash
mvn clean package
java -jar target/my-app-1.0.0-SNAPSHOT.jar
```

The parent uses the repository's normal Shade and ProGuard packaging instead of Micronaut's Maven lifecycle extension.
The shared `size-optimization` profile therefore remains available. For Micronaut applications, ProGuard performs
shrinking without optimization or obfuscation and preserves generated bean definitions, serialization metadata,
application entry points, and the `META-INF/micronaut` service index.

# Micronaut Processing

The parent configures KSP processors for Micronaut dependency injection, Micronaut Data, Micronaut Serialization,
OpenAPI generation, and validation. KSP requires Maven 3.9.16 or newer.

KSP is used instead of KAPT because KAPT is in maintenance mode, while KSP is actively developed. KSP also avoids the
duplicate generated-source roots produced by the previous KAPT setup and writes Micronaut's generated bean definitions
directly to the Maven main and test output directories.

When running `mvn mn:run`, the `process-main-sources` KSP execution currently appears twice. The Micronaut Maven plugin
first invokes the Maven lifecycle through `process-classes` and then starts another `process-classes` build for its
development watch mode. Consequently, KSP and the Kotlin compiler both run twice during the initial application start;
this is behavior of `mn:run`, not duplicate KSP configuration in this parent. The KSP Maven plugin does not provide
Gradle-style up-to-date checks that skip processing when the sources are unchanged, so retaining the `target` directory
does not avoid this startup cost.

# Test Resources

The managed Micronaut Maven plugin starts and stops Micronaut Test Resources around integration tests. Test Resources
uses Testcontainers to provision infrastructure such as MongoDB and RabbitMQ when their connection properties are
missing and is enabled by default. The plugin runs without Micronaut's lifecycle extension and does not take over
application packaging.

Declare `micronaut-test-resources-client` with test scope when integration tests need values supplied by Test Resources:

```xml
<dependency>
  <groupId>io.micronaut.testresources</groupId>
  <artifactId>micronaut-test-resources-client</artifactId>
  <scope>test</scope>
</dependency>
```

# Shared Features

The following applicable features are documented in [Features.md](Features.md):

- [Testing](Features.md#run-tests)
- [Compiler warnings](Features.md#compiler-warnings)
- [Integration tests with real infrastructure](Features.md#integration-tests-with-real-infrastructure)
- [Versioned database migrations](Features.md#versioned-database-migrations)
- [Generated API documentation](Features.md#generated-api-documentation)
- [Application health](Features.md#application-health)
- [Container image](Features.md#container-image)
- [Request validation](Features.md#request-validation)
- [Offline builds and external API simulation](Features.md#offline-builds-and-external-api-simulation)
- [SBOM](Features.md#software-bill-of-materials)
- [Vulnerability scanning](Features.md#vulnerability-scanning)
- [Code coverage](Features.md#code-coverage)
- [Executable application JARs](Features.md#executable-application-jars)
- [Size optimization](Features.md#size-optimization)
- [License check](Features.md#license-check)
- [Code formatting](Features.md#code-formatting)
- [Pre-commit hook](Features.md#pre-commit-hook)
- [Signing](Features.md#signing)
- [Maintenance](Features.md#maintenance)
- [Troubleshooting](Features.md#troubleshooting)

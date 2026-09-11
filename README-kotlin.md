# Kotlin/JVM Project Setup

This guide covers how to use the `parent-kotlin.xml` parent POM for pure Kotlin/JVM projects.

> For shared concepts such as testing, SBOMs, coverage, signing, and formatting, see [Features.md](Features.md).

- [How to Use](#how-to-use)
- [Source Layout](#source-layout)
- [Build](#build)
  - [Build command](#build-command)
  - [Shaded executable JAR](#shaded-executable-jar)
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
    <artifactId>kotlin-parent</artifactId>
    <version>1.0.0-rc.1</version>
    <relativePath />
  </parent>

  <groupId>com.example</groupId>
  <artifactId>my-app</artifactId>
  <version>1.0-SNAPSHOT</version>

  <properties>
    <main.class>com.example.Main</main.class>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.jetbrains.kotlin</groupId>
      <artifactId>kotlin-stdlib</artifactId>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.jetbrains.kotlin</groupId>
        <artifactId>kotlin-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
```

Configure GitHub Packages as described in [README.md](README.md#configure-github-packages) so Maven can resolve the
parent and its shared configuration artifacts.

A complete project with tests and all optional plugins is available in [`examples/kotlin/`](examples/kotlin/).

# Source Layout

The parent is intended for pure Kotlin/JVM projects and uses these source directories:

```text
src/main/kotlin
src/test/kotlin
src/test-integration/kotlin
src/test-integration/resources
```

Kotlin and Java compilation target JVM 25. The parent does not configure mixed Java/Kotlin compilation.

# Build

## Build command

```bash
mvn clean verify
```

This runs Kotlin compilation, unit tests, and JAR packaging. Enforcer checks and integration tests require the consumer
POM to activate the inherited `maven-enforcer-plugin`, `maven-failsafe-plugin`, and `build-helper-maven-plugin`
configurations. The complete [`examples/kotlin/pom.xml`](examples/kotlin/pom.xml) demonstrates these declarations.

## Shaded executable JAR

Activate the inherited Git metadata and Shade configurations in the consumer POM:

```xml
<plugin>
  <groupId>io.github.git-commit-id</groupId>
  <artifactId>git-commit-id-maven-plugin</artifactId>
</plugin>
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-shade-plugin</artifactId>
</plugin>
```

Use a named Kotlin object with a static JVM entry point so `<main.class>` maps directly to the generated class:

```kotlin
package com.example

object Main {
  @JvmStatic
  fun main(args: Array<String>) {
    println("Hello, Kotlin")
  }
}
```

A top-level `main` function in `Main.kt` compiles to `MainKt` and would instead require
`<main.class>com.example.MainKt</main.class>`.

# Shared Features

- [Testing](Features.md#run-tests)
- [SBOM](Features.md#software-bill-of-materials)
- [Vulnerability scanning](Features.md#vulnerability-scanning)
- [Code coverage](Features.md#code-coverage)
- [License check](Features.md#license-check)
- [Code formatting](Features.md#code-formatting)
- [Pre-commit hook](Features.md#pre-commit-hook)
- [Signing](Features.md#signing)
- [Maintenance](Features.md#maintenance)
- [Troubleshooting](Features.md#troubleshooting)

# Java Project Setup

This guide covers how to use the `parent-java.xml` parent POM for plain Java projects.

> 💡 For shared concepts (SBOM, vulnerability scanning, code coverage, license check, code formatting, signing, maintenance, troubleshooting) see [README.md](README.md).

- [How to Use](#how-to-use)
- [Build](#build)
  - [Build command](#build-command)
  - [Shaded (fat) .jar](#shaded-fat-jar)
- [Shared Features](#shared-features)

# How to Use

Create a `pom.xml` in your project:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>my-app</artifactId>
  <version>1.0-SNAPSHOT</version>

  <parent>
    <groupId>de.neonew</groupId>
    <artifactId>java-parent</artifactId>
    <version>1.0.0-rc.1</version>
    <relativePath />
  </parent>

  <properties>
    <main.class>com.example.Main</main.class>
  </properties>

  <!-- your dependencies, plugins, etc. -->
</project>
```

> 💡 A fully working example is available in [`examples/java/`](examples/java/).

Configure GitHub Packages as described in [README.md](README.md#configure-github-packages) so Maven can resolve the
parent and its shared configuration artifacts.

# Build

## Build command

```bash
mvn clean verify
```

This runs the enforcer checks, compilation, unit tests (surefire), integration tests
(failsafe), and JAR packaging. Optional features such as coverage, SBOM generation,
license checks, formatting checks, and signing require their respective profiles.

## Shaded (fat) .jar

The project can produce a shaded (fat) JAR with the `maven-shade-plugin`.
The fat JAR is placed in `target/` and named after the git commit describe
(e.g. `your-app-a1b2c3d.jar`).

Activate it by adding the `shade` and `git-commit-id` plugins to your `pom.xml`:

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

Set the `<main.class>` property to your application's entry point. The inherited
`ManifestResourceTransformer` writes it as `Main-Class` to the shaded JAR's manifest.

# Shared Features

The following features are shared across all project types and documented in [README.md](README.md):

- [SBOM](README.md#software-bill-of-materials-sbom)
- [Vulnerability scanning](README.md#vulnerability-scanning)
- [Code coverage](README.md#code-coverage)
- [License check](README.md#license-check)
- [Code formatting](README.md#code-formatting)
- [Pre-commit hook](README.md#pre-commit-hook)
- [Signing](README.md#signing)
- [Maintenance](README.md#maintenance)
- [Troubleshooting](README.md#troubleshooting)

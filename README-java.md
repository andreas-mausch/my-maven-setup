# Java Project Setup

This guide covers how to use the `parent-java.xml` parent POM for plain Java projects.

> 💡 For shared concepts such as testing, SBOMs, coverage, signing, and formatting, see [Features.md](Features.md).

- [How to Use](#how-to-use)
- [Build](#build)
  - [Build command](#build-command)
  - [Shaded (fat) .jar](#shaded-fat-jar)
  - [Size Optimization](#size-optimization)
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
    <artifactId>java-parent</artifactId>
    <version>1.0.0-rc.1</version>
    <relativePath />
  </parent>

  <groupId>com.example</groupId>
  <artifactId>my-app</artifactId>
  <version>1.0-SNAPSHOT</version>

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

This runs compilation, unit tests (surefire), and JAR packaging. Enforcer checks and
integration tests require the consumer POM to activate the inherited `maven-enforcer-plugin`,
`maven-failsafe-plugin`, and `build-helper-maven-plugin` configurations. The complete
[`examples/java/pom.xml`](examples/java/pom.xml) demonstrates these declarations. Optional
features such as coverage, SBOM generation, license checks, formatting checks, and signing
require their respective profiles.

Integration tests belong under `src/test-integration/java` and must use a package containing `.integration.`, such as
`com.example.integration`. Surefire excludes these packages from unit-test runs, while Failsafe includes them during
`verify`.

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

## Size Optimization

To reduce the application JAR's size by removing unused code and applying further bytecode optimizations, activate the
optional `size-optimization` profile:

```bash
mvn clean verify -Psize-optimization
```

The current implementation uses ProGuard, which also obfuscates names during processing. The profile processes the
regular project JAR and attaches the result as
`target/<artifactId>-<version>-proguard.jar`. The regular JAR remains the main Maven artifact. Set the inherited
`main.class` property to the application's entry point; ProGuard keeps that class and its `main` method. Projects using
reflection, dependency injection, serialization, native methods, or additional Java modules may need project-specific
keep rules or further JMOD library entries in their plugin configuration.

# Shared Features

The following features are shared across all project types and documented in [Features.md](Features.md):

- [SBOM](Features.md#software-bill-of-materials)
- [Vulnerability scanning](Features.md#vulnerability-scanning)
- [Code coverage](Features.md#code-coverage)
- [Size optimization](Features.md#size-optimization)
- [License check](Features.md#license-check)
- [Code formatting](Features.md#code-formatting)
- [Pre-commit hook](Features.md#pre-commit-hook)
- [Signing](Features.md#signing)
- [Maintenance](Features.md#maintenance)
- [Troubleshooting](Features.md#troubleshooting)

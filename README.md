# Table of Contents

- [About This Project](#about-this-project)
- [Available Parent POMs](#available-parent-poms)
- [How to Use](#how-to-use)
  - [For a plain Java project](#for-a-plain-java-project)
  - [For a JavaCard applet](#for-a-javacard-applet)
- [Build](#build)
  - [Requirements](#requirements)
  - [Prerequisite: api_classic.jar (JavaCard only)](#prerequisite-api_classicjar-javacard-only)
  - [Build command](#build-command)
  - [What gets built](#what-gets-built)
  - [Run single test](#run-single-test)
- [Configuration](#configuration)
- [Software Bill of Materials (SBOM)](#software-bill-of-materials-sbom)
- [Vulnerability scanning](#vulnerability-scanning)
- [Shaded (fat) .jar](#shaded-fat-jar)
- [License check](#license-check)
- [Signing](#signing)
  - [Verify a signed release](#verify-a-signed-release)
- [Maintenance](#maintenance)

# About This Project

**my-maven-setup** is my personal, opinionated Maven parent POM collection.
It provides ready-to-use parent POMs for different project types so I don't have
to repeat the same plugin/dependency configuration in every project.

Currently available:
- **Java** (`parent-java.xml`) — general Java project setup
- **JavaCard** (`parent-javacard.xml`) — JavaCard applet build setup (extends Java)

Planned:
- Kotlin
- Kotlin-Micronaut
- more to come

Each type also has a matching example project in the `examples/` directory.

# Available Parent POMs

| Parent POM | Artifact | Description |
|------------|----------|-------------|
| `parent-java.xml` | `com.parent:java:1.0.0` | General Java: compiler, JAR, enforcer, surefire, failsafe, JaCoCo, git-commit-id, versions, GPG signing, CycloneDX/SPDX SBOM, license checks, shade plugin |
| `parent-javacard.xml` | `com.parent:javacard:1.0.0` | JavaCard applet: extends `java`, adds JDK 8 cross-compilation, ProGuard obfuscation, JCDK packaging, jCardSim for integration tests |

# How to Use

## For a plain Java project

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
    <groupId>com.parent</groupId>
    <artifactId>java</artifactId>
    <version>1.0.0</version>
    <relativePath>path/to/parent-java.xml</relativePath>
  </parent>

  <!-- your dependencies, plugins, etc. -->
</project>
```

## For a JavaCard applet

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>my-applet</artifactId>
  <version>1.0-SNAPSHOT</version>

  <parent>
    <groupId>com.parent</groupId>
    <artifactId>javacard</artifactId>
    <version>1.0.0</version>
    <relativePath>path/to/parent-javacard.xml</relativePath>
  </parent>

  <properties>
    <applet.id>01:02:03:04:05:06</applet.id>
    <applet.main.class>com.example.MyApplet</applet.main.class>
  </properties>

  <!-- your dependencies, plugins, etc. -->
</project>
```

# Build

## Requirements

> ⚠️ **You need JDK 8 installed** if you build JavaCard applets. The applet code
> is compiled against Java 1.1 (`-target 1.1`), which modern JDKs reject.
>
> Only the applet compilation step requires JDK 8. Maven and tests run on any
> modern JDK (21 required by enforcer plugin).

- **JDK 21+** for Maven and tests
- **JDK 8** (`javac`) for JavaCard applet compilation (if using `parent-javacard.xml`)
- **Maven 3.6+**

## Prerequisite: api_classic.jar (JavaCard only)

Before the first build of a JavaCard project, install the JavaCard SDK's
`api_classic.jar` into your local Maven repository. This is a one-time step:

```bash
mvn install:install-file \
  -Dfile=path/to/jc305u4_kit/lib/api_classic.jar \
  -DgroupId=com.oracle.javacard -DartifactId=api-classic \
  -Dversion=3.0.5 -Dpackaging=jar
```

The exact `javacard.sdk.path` property in `parent-javacard.xml` must point to the
root of your JavaCard SDK installation.

## Build command

```bash
mvn clean verify -Djava.compiler.main.path=/path/to/jdk8/bin/javac
```

The `-Djava.compiler.main.path` argument is **required** for JavaCard projects:
the build will fail without it. This tells the compiler which JDK 8 `javac` to use
for applet code.

To avoid passing it every time, persist it in `.mvn/maven.config`:

```bash
echo '-Djava.compiler.main.path=/path/to/jdk8/bin/javac' > .mvn/maven.config
```

## What gets built

After a successful `mvn clean verify` of a JavaCard project, you'll find these
artifacts in `target/`:

| Artifact                | Description                                        |
|-------------------------|----------------------------------------------------|
| `010203040506.cap`      | JavaCard applet binary (named after the AID)       |
| `your-applet-*.jar`     | Regular JAR of the compiled applet classes         |

## Run single test

```bash
mvn test [-Dtest=TestClass#testMethod]
mvn failsafe:integration-test [-Dit.test=TestClass#testMethod]
```

# Configuration

The Maven configuration is split across three files:

- `pom.xml` in your project: project-specific settings, plugins and dependencies.
- `parent-javacard.xml`: configuration shared across all JavaCard projects.
- `parent-java.xml`: general Maven settings for Java projects; also specifies
  plugin versions and default configuration.

For JavaCard projects, the following properties **must** be defined in your project's `pom.xml`:
- `<applet.id>`: JavaCard AID (e.g. `01:02:03:04:05:06`)
- `<applet.main.class>`: fully qualified applet class (e.g. `com.example.MyApplet`)

`<applet.version>` is automatically derived from `<version>` by stripping any
qualifier (e.g. `1.0-SNAPSHOT` → `1.0`). You can still override it explicitly.

# Software Bill of Materials (SBOM)

The project includes two SBOM generators (opt-in via your `pom.xml`):

- **CycloneDX** (`org.cyclonedx:cyclonedx-maven-plugin`): security-focused,
  excludes test dependencies. Output: `target/bom.json`
- **SPDX** (`org.spdx:spdx-maven-plugin`): license/compliance-focused,
  includes all scopes. Output: `target/site/{project-name}-{version}.spdx.json`

Both run during `mvn package` and produce JSON. Activate them with the `sbom` profile:

```bash
mvn clean package -Psbom
```

# Vulnerability scanning

Scan the generated SBOM for vulnerabilities with [Grype](https://github.com/anchore/grype):

```bash
grype sbom:target/bom.json --fail-on high
```

# Shaded (fat) .jar

The project can produce a shaded (fat) JAR with the `maven-shade-plugin`.
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

Set `<mainClass>` via a `ManifestResourceTransformer` in your own configuration
if you need an executable JAR.

# License check

Enforce that all dependencies use only FOSS licenses with the `license-check`
profile:

```bash
mvn clean verify -Plicense-check
```

The build fails if any dependency has a license not in the FOSS allowlist or is
missing license metadata.

License aliases and the allowlist are defined in `parent-java.xml` under
`<licenseMerges>` and `<includedLicenses>`. Project-specific overrides (e.g.
for the Oracle JavaCard SDK) can be added in `parent-javacard.xml` via
`combine.children="append"` and a `license-override.properties` file in the
project root.

# Signing

Artifacts can be signed with GPG using the `sign` profile. You must specify the
key fingerprint via `-Dgpg.key`:

```bash
mvn -Psign -Dgpg.key=1234567890ABCDEF1234567890ABCDEF1234567890 clean verify
```

Find your key fingerprint with `gpg --list-secret-keys`.

## Verify a signed release

Each release artifact (`.jar`, `.cap`, `.pom`) has a matching `.asc` signature
file. To verify it's from the correct author:

```bash
gpg --verify my-applet-1.0.asc my-applet-1.0.cap
```

You need the author's public key imported. It can be downloaded from a key server:

```bash
gpg --keyserver keys.openpgp.org --recv-key 1234567890ABCDEF1234567890ABCDEF1234567890
```

Replace the key ID with the one used for signing.

# Maintenance

Update dependency versions:

```bash
mvn versions:display-dependency-updates
mvn versions:display-plugin-updates
mvn versions:display-property-updates -DincludeParent
```

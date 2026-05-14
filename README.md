# Table of Contents

- [About This Project](#about-this-project)
- [Applet Overview](#applet-overview)
- [Build](#build)
  - [Requirements](#requirements)
  - [Prerequisite: api_classic.jar](#prerequisite-api_classicjar)
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

This project is a minimal Maven-based build setup for JavaCard applets, using JCardSim for integration testing. It demonstrates how to compile, test, and package a JavaCard applet in a modern CI-friendly workflow.

JavaCard is a platform for writing Java applets that run on smart cards, tiny secure chips used in payment cards, SIM cards, access control, and more. A JavaCard applet is a small program (typically a few KB) that communicates with readers via APDU commands over ISO 7816.

For more on JavaCard:
- [Oracle JavaCard Platform](https://www.oracle.com/java/java-card/)
- [ISO/IEC 7816-4:2020 - Organization, security and commands for interchange](https://www.iso.org/standard/77180.html)
- [JCardSim documentation](https://github.com/licel/jcardsim)

# Applet Overview

The applet responds to a custom APDU command with `"Hello"`:

```
Client                          HelloWorldApplet
  |                                   |
  |  CLA=0x80 INS=0x00                |
  |---------------------------------->|
  |                                   | returns "Hello" + SW=0x9000
  |<----------------------------------|
```

- **CLA:** `0x80` (custom): any other value returns `SW=0x6E00` (CLA not supported)
- **INS:** `0x00`: returns the byte array `"Hello"` with `SW=0x9000` (success)
- Any other INS returns `SW=0x6D00` (instruction not supported)

# Build

## Requirements

> ⚠️ **You need JDK 8 installed.** The applet code is compiled against Java 1.1 (`-target 1.1`), which modern JDKs reject.
>
> Only the applet compilation step requires JDK 8. Maven and tests run on any modern JDK (21 required by enforcer plugin).

This project uses two separate Java compilers:

- **Main sources (applet code)**: compiled against Java 1.1 with a **JDK 8** `javac`. You must specify the path to your JDK 8 `javac` via `-Djava.compiler.main.path`. If you increase the target version beyond 1.1, the resulting `.cap` file may not run on all JavaCards.
- **Test sources**: compiled normally using whatever JDK is on your `$PATH` / `$JAVA_HOME` (JDK 21 required by enforcer plugin).

## Prerequisite: api_classic.jar

Before the first build, install the JavaCard SDK's `api_classic.jar` into your local
Maven repository. This is a one-time step:

```bash
mvn install:install-file \
  -Dfile=../../../external/oracle_javacard_sdks/jc305u4_kit/lib/api_classic.jar \
  -DgroupId=com.oracle.javacard -DartifactId=api-classic \
  -Dversion=3.0.5 -Dpackaging=jar
```

## Build command

Then build the project:

```bash
mvn clean verify -Djava.compiler.main.path=/path/to/jdk8/bin/javac
```

The `-Djava.compiler.main.path` argument is **required**: the build will fail without it.
This tells the compiler which JDK 8 `javac` to use for applet code.

To avoid passing it every time, persist it in `.mvn/maven.config`:

```bash
echo '-Djava.compiler.main.path=/path/to/jdk8/bin/javac' > .mvn/maven.config
```

## What gets built

After a successful `mvn clean verify`, you'll find these artifacts in `target/`:

| Artifact                | Description                                        |
|-------------------------|----------------------------------------------------|
| `010203040506.cap`      | JavaCard applet binary (named after the AID)       |
| `javacard-applet-*.jar` | Regular JAR of the compiled applet classes         |

## Run single test

```bash
mvn test [-Dtest=TestClass#testMethod]
mvn failsafe:integration-test [-Dit.test=TestClass#testMethod]
```

# Configuration

The Maven configuration is split across three files:

- `pom.xml`: project-specific settings, plugins and dependencies.
- `parent-javacard.xml`: configuration shared across all JavaCard projects.
- `parent-java.xml`: general Maven settings for Java projects; also specifies plugin versions and default configuration.

The following properties **must** be defined in `pom.xml`:
- `<applet.id>`: JavaCard AID (e.g. `01:02:03:04:05:06`)
- `<applet.main.class>`: fully qualified applet class (e.g. `helloworld.HelloWorldApplet`)

`<applet.version>` is automatically derived from `<version>` by stripping any
qualifier (e.g. `1.0-SNAPSHOT` → `1.0`). You can still override it explicitly.

# Software Bill of Materials (SBOM)

The project includes two SBOM generators (opt-in via `pom.xml`):

- **CycloneDX** (`org.cyclonedx:cyclonedx-maven-plugin`): security-focused, excludes test dependencies.
  Output: `target/bom.json`
- **SPDX** (`org.spdx:spdx-maven-plugin`): license/compliance-focused, includes all scopes.
  Output: `target/site/{project-name}_javacard-applet-{version}.spdx.json`

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
Activate it by adding the `shade` and `git-commit-id` plugins:

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

Artifacts can be signed with GPG using the `sign` profile. You must specify the key fingerprint via `-Dgpg.key`:

```bash
mvn -Psign -Dgpg.key=1234567890ABCDEF1234567890ABCDEF1234567890 clean verify
```

Find your key fingerprint with `gpg --list-secret-keys`.

## Verify a signed release

Each release artifact (`.jar`, `.cap`, `.pom`) has a matching `.asc` signature file. To verify it's from the correct author:

```bash
gpg --verify javacard-applet-1.0.asc javacard-applet-1.0.cap
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

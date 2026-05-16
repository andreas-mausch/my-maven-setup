# JavaCard Project Setup

This guide covers how to use the `parent-javacard.xml` parent POM for JavaCard applet projects.

> 💡 For shared concepts (SBOM, vulnerability scanning, code coverage, license check, signing, maintenance, troubleshooting) see [README.md](README.md).

- [How to Use](#how-to-use)
- [JavaCard SDK](#javacard-sdk)
- [Local Maven repository setup for api_classic.jar](#local-maven-repository-setup-for-api_classicjar)
- [Required properties](#required-properties)
- [Build](#build)
  - [Build command](#build-command)
  - [What gets built](#what-gets-built)
- [Troubleshooting](#troubleshooting)
- [Shared Features](#shared-features)

# How to Use

Create a `pom.xml` in your project:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>my-applet</artifactId>
  <version>1.0-SNAPSHOT</version>

  <parent>
    <groupId>de.neonew</groupId>
    <artifactId>javacard-parent</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <relativePath>path/to/parent-javacard.xml</relativePath>
  </parent>

  <properties>
    <applet.id>01:02:03:04:05:06</applet.id>
    <applet.main.class>com.example.MyApplet</applet.main.class>
  </properties>

  <!-- your dependencies, plugins, etc. -->
</project>
```

> 💡 A fully working example is available in [`examples/javacard/`](examples/javacard/).

# JavaCard SDK

The JavaCard SDK provides the `api_classic.jar` library, which contains the
`javacard.framework` packages needed to compile applet code. It is also used
by the JCDK plugin to package the applet.

> 💡 SDKs can be downloaded from [martinpaljak/oracle_javacard_sdks](https://github.com/martinpaljak/oracle_javacard_sdks).

# Local Maven repository setup for api_classic.jar

Before the first build of a JavaCard project, install the JavaCard SDK's
`api_classic.jar` into your local Maven repository. This is a one-time step:

```bash
mvn install:install-file \
  -Dfile=/path/to/javacard/sdk/lib/api_classic.jar \
  -DgroupId=com.oracle.javacard -DartifactId=api-classic \
  -Dversion=3.0.5 \
  -Dpackaging=jar
```

# Required properties

For JavaCard projects, the following properties **must** be set:

- `<applet.id>`: JavaCard AID (e.g. `01:02:03:04:05:06`) — in your `pom.xml`
- `<applet.main.class>`: fully qualified applet class (e.g. `com.example.MyApplet`) — in your `pom.xml`
- `java.compiler.main.path`: path to your JDK 8 `javac` binary — via `-D` command line argument
- `javacard.sdk.path`: path to your JavaCard SDK installation (e.g. `/opt/javacard/jc305u4_kit`) — via `-D` command line argument

`<applet.version>` is automatically derived from `<version>` by stripping any
qualifier (e.g. `1.0-SNAPSHOT` → `1.0`). You can still override it explicitly.

# Build

## Build command

```bash
mvn clean verify \
  -Djava.compiler.main.path=/path/to/jdk8/bin/javac \
  -Djavacard.sdk.path=/path/to/javacard/sdk
```

Both `-Djava.compiler.main.path` and `-Djavacard.sdk.path` are **required** for
JavaCard projects: the build will fail without them.

To avoid passing them every time, persist them in `.mvn/maven.config`:

```bash
echo '-Djava.compiler.main.path=/path/to/jdk8/bin/javac' > .mvn/maven.config
echo '-Djavacard.sdk.path=/path/to/javacard/sdk' >> .mvn/maven.config
```

## What gets built

After a successful `mvn clean verify` of a JavaCard project, you'll find these
artifacts in `target/`:

| Artifact            | Description                                  |
|---------------------|----------------------------------------------|
| `010203040506.cap`  | JavaCard applet binary (named after the AID) |
| `your-applet-*.jar` | Regular JAR of the compiled applet classes   |

# Troubleshooting

## SPDX: Unknown relationship type for `provided` dependencies

```
[WARNING] Could not determine the SPDX relationship type for dependency artifact ID api-classic scope provided
```

The SPDX plugin does not have a mapping for the Maven `provided` scope. This only affects the `api-classic`
dependency from the Oracle JavaCard SDK and does not affect the generated SPDX document.

# Shared Features

The following features are shared across all project types and documented in [README.md](README.md):

- [SBOM](README.md#software-bill-of-materials-sbom)
- [Vulnerability scanning](README.md#vulnerability-scanning)
- [Code coverage](README.md#code-coverage)
- [License check](README.md#license-check)
- [Signing](README.md#signing)
- [Maintenance](README.md#maintenance)
- [Troubleshooting](README.md#troubleshooting) (shared warnings)

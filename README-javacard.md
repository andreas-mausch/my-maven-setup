# JavaCard Project Setup

This guide covers how to use the `parent-javacard.xml` parent POM for JavaCard applet projects.

`javacard-parent` extends `java-parent`. See [README-java.md](README-java.md) for the inherited Java build
configuration.

> 💡 For shared concepts such as testing, SBOMs, coverage, signing, and formatting, see [Features.md](Features.md).

- [How to Use](#how-to-use)
- [JavaCard SDK](#javacard-sdk)
- [Local Maven repository setup for api_classic.jar](#local-maven-repository-setup-for-api_classicjar)
- [AIDs](#aids)
- [Required properties](#required-properties)
- [Build](#build)
  - [Build command](#build-command)
  - [Applet Size Optimization](#applet-size-optimization)
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

  <parent>
    <groupId>de.neonew.build</groupId>
    <artifactId>javacard-parent</artifactId>
    <version>1.0.0</version>
    <relativePath />
  </parent>

  <groupId>com.example</groupId>
  <artifactId>my-applet</artifactId>
  <version>1.0-SNAPSHOT</version>

  <properties>
    <applet.id>F0:01:02:03:04:01</applet.id>
    <main.class>com.example.MyApplet</main.class>
  </properties>

  <!-- your dependencies, plugins, etc. -->
</project>
```

> 💡 A fully working example is available in [`examples/javacard/`](examples/javacard/).

The parent POM and its shared configuration artifacts resolve from Maven Central; see
[Available Parent POMs](README.md#available-parent-poms).

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

# AIDs

JavaCard distinguishes three kinds of AIDs:

- **Package AID** — identifies a loadable package, i.e. the contents of a CAP file.
  Each CAP file defines exactly one package AID (GlobalPlatform: Load File AID).
- **Applet AID** — identifies an applet *class* recorded in the CAP file's Applet
  component (GlobalPlatform: Executable Module AID).
- **Instance AID** — identifies an installed, selectable applet instance; it is the
  AID a terminal addresses with the ISO 7816 `SELECT` command (GlobalPlatform:
  Application AID). It is assigned at install time; a default install creates the
  instance under the applet AID, which is common practice for applets with a single
  instance.

Both are plain AIDs as defined by ISO/IEC 7816-5: 5–16 bytes, consisting of a 5-byte
**RID** (registered application provider identifier) followed by 0–11 bytes of
**PIX** (proprietary application identifier extension).

The JavaCard converter enforces that an applet AID starts with the 5-byte RID of the
package AID; a longer common prefix is conventional but not required. The usual
convention is instance AID = package AID + a one-byte instance number, e.g. package
`01:02:03:04:05`, applet instance `01:02:03:04:05:01`. For production cards, use your
organization's registered RID (ISO/IEC 7816-5 registration); for testing, a locally
assigned unregistered RID is fine.

## How this build handles AIDs

`<applet.id>` is the **applet AID**, 6 to 12 hex bytes separated by colons. It is
written into the CAP's Applet component and, with a default install, also used as the
instance AID — the AID `SELECT` addresses. The **package AID is derived from the first
5 bytes** — the jcdk-maven-plugin used for CAP generation hard-codes this rule, and the
result always equals the RID, so the converter rule above is satisfied automatically.

Example for `<applet.id>F0:01:02:03:04:01</applet.id>`:

| Property              | Value               | Description                                              |
|-----------------------|---------------------|----------------------------------------------------------|
| `applet.id`           | `F0:01:02:03:04:01` | Applet AID; default-install instance AID for `SELECT`    |
| `applet.id.nocolons`  | `F00102030401`      | Same, without colons                                     |
| `package.id`          | `F0:01:02:03:04`    | Package AID (auto-derived — never set it manually)       |
| `package.id.nocolons` | `F001020304`        | Package AID without colons                               |
| `applet.version`      | `1.0`               | JavaCard package version derived from `<version>`       |

Integration tests get all four build properties as system properties via the
maven-failsafe-plugin: `javacard.applet.id`, `javacard.applet.id.nocolons`,
`javacard.package.id` and `javacard.package.id.nocolons`. The names are dotted,
lower-case and share the `javacard.` prefix to stay clear of JDK and library
properties. Read them with `System.getProperty(...)` instead of hard-coding AIDs in
test code — for example `Hex.decode(System.getProperty("javacard.applet.id.nocolons"))`.

About artifact naming: the plain Oracle converter names the CAP after the Java package
name (e.g. `helloworld.cap`). The jcdk-maven-plugin renames it after the **applet
AID** (`F00102030401.cap`), and that is the file attached to the build. Other
JavaCard tools often name CAP files after the *package* AID instead; use
`${package.id.nocolons}` if you need that form.

# Required properties

For JavaCard projects, the following properties **must** be set:

- `<applet.id>`: applet AID, 6–12 hex bytes separated by colons (e.g. `F0:01:02:03:04:01`); with a default install it is also the selectable instance AID. The package AID is derived from its first 5 bytes, see [AIDs](#aids) — in your `pom.xml`
- `<main.class>`: fully qualified applet class (e.g. `com.example.MyApplet`) — in your `pom.xml`
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

Integration tests belong under `src/test-integration/java` and must use a package containing `.integration.`, such as
`com.example.integration`. Surefire excludes these packages from unit-test runs, while Failsafe includes them during
`verify`.

To avoid passing them every time, persist them in `.mvn/maven.config`:

```bash
mkdir -p .mvn
echo '-Djava.compiler.main.path=/path/to/jdk8/bin/javac' > .mvn/maven.config
echo '-Djavacard.sdk.path=/path/to/javacard/sdk' >> .mvn/maven.config
```

## Applet Size Optimization

The `.cap` is always produced by JCDK during `package`. For JavaCard size optimization, the `size-optimization` profile
removes unused code and applies further bytecode optimizations before JCDK packages the classes. The current
implementation uses ProGuard:

```bash
mvn clean verify \
  -Djava.compiler.main.path=/path/to/jdk8/bin/javac \
  -Djavacard.sdk.path=/path/to/javacard/sdk \
  -Psize-optimization
```

## What gets built

After a successful `mvn clean verify` of a JavaCard project, you'll find these
artifacts in `target/`:

| Artifact            | Description                                  |
|---------------------|----------------------------------------------|
| `F00102030401.cap`  | JavaCard applet binary (named after the applet AID, see [AIDs](#aids)) |
| `your-applet-*.jar` | Regular JAR of the compiled applet classes   |

With the `size-optimization` profile, the `.cap` is shrunk by ProGuard for a smaller
footprint on the smart card.

# Shared Features

The following shared documentation applies:

- [Testing](Features.md#run-tests)
- [Compiler warnings](Features.md#compiler-warnings)
- [SBOM](Features.md#software-bill-of-materials)
- [Vulnerability scanning](Features.md#vulnerability-scanning)
- [Code coverage](Features.md#code-coverage)
- [Size optimization](Features.md#size-optimization)
- [License check](Features.md#license-check)
- [Code formatting](Features.md#code-formatting)
- [Pre-commit hook](Features.md#pre-commit-hook)
- [Signing](Features.md#signing)
- [Maintenance](Features.md#maintenance)
- [Troubleshooting](Troubleshooting.md)

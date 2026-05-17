# JavaCard Hello World

A minimal JavaCard applet demonstrating every feature of the
[`de.neonew:javacard-parent`](../../parent-javacard.xml) POM.

## What it does

A simple JavaCard applet that responds to a custom APDU command with `"Hello"`:

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

## Local Maven repository setup for api_classic.jar

Before the first build, install the JavaCard SDK's `api_classic.jar` into your
local Maven repository (one-time step):

```bash
mvn install:install-file \
  -Dfile=/path/to/javacard/sdk/lib/api_classic.jar \
  -DgroupId=com.oracle.javacard -DartifactId=api-classic \
  -Dversion=3.0.5 \
  -Dpackaging=jar
```

## Required properties

For JavaCard projects, the following properties **must** be set:

- `<applet.id>`: JavaCard AID (e.g. `01:02:03:04:05:06`) — in your `pom.xml`
- `<main.class>`: fully qualified applet class (e.g. `com.example.MyApplet`) — in your `pom.xml`
- `java.compiler.main.path`: path to your JDK 8 `javac` binary — via `-D` command line argument
- `javacard.sdk.path`: path to your JavaCard SDK installation — via `-D` command line argument

`<applet.version>` is automatically derived from `<version>` by stripping any
qualifier (e.g. `1.0-SNAPSHOT` → `1.0`). You can still override it explicitly.

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

### Optimized build (with ProGuard shrinking)

The `.cap` is always produced by JCDK during `package`. For JavaCard size
optimization, ProGuard can be activated via the `proguard` profile — it shrinks
classes before JCDK packages them:

```bash
mvn clean verify \
  -Djava.compiler.main.path=/path/to/jdk8/bin/javac \
  -Djavacard.sdk.path=/path/to/javacard/sdk \
  -Pproguard
```

### What gets built

After a successful `mvn clean verify`, you'll find these artifacts in `target/`:

| Artifact                     | Description                                      |
|------------------------------|--------------------------------------------------|
| `javacard-hello-world-*.jar` | Regular JAR of the compiled applet classes       |
| `010203040506.cap`           | JavaCard applet binary (named after the AID)     |

With the `proguard` profile, the `.cap` is shrunk by ProGuard for a smaller
footprint on the smart card.

### Run only unit tests

```bash
mvn test
```

### Run only integration tests

```bash
mvn failsafe:integration-test
```

## Features demonstrated

| Feature                          | How it's used                                                                      |
|----------------------------------|------------------------------------------------------------------------------------|
| **Enforcer**                     | Validates JDK 21+ and Maven 3.6+ on every build                                    |
| **JDK 8 cross-compilation**      | Applet compiled against Java 1.1 with JDK 8 javac, tests compiled on JDK 21        |
| **JUnit 5 + AssertJ**            | All tests use JUnit Jupiter and AssertJ (versions managed by parent)               |
| **Surefire (unit tests)**        | `HelloWorldAppletTest` — 1 test, excluded from failsafe                            |
| **Failsafe (integration tests)** | `HelloWorldAppletTest` — 3 tests in `.integration.` package, runs during `verify`  |
| **build-helper**                 | Adds `src/test-integration/java` and `src/test-integration/resources`              |
| **JaCoCo**                       | Coverage agent runs during tests; HTML report in `target/site/jacoco/`             |
| **JaCoCo console reporter**      | Coverage summary printed to console after `verify`                                 |
| **ProGuard**                     | Obfuscates applet classes before JCDK packaging                                    |
| **JCDK packaging**               | Produces `.cap` file named after the AID                                           |
| **git-commit-id**                | Git commit info embedded in `META-INF/git.properties` inside the JAR               |
| **Shade plugin**                 | Produces a fat JAR `target/javacard-hello-world-*.jar` alongside the regular one   |
| **versions-maven-plugin**        | Inherited from parent — run `mvn versions:display-*` to check for updates           |

### SBOM (Software Bill of Materials)

Generates CycloneDX and SPDX JSON documents listing all dependencies:

```bash
mvn clean package -Psbom
```

Output:
- `target/bom.json` — CycloneDX
- `target/site/<name>-<version>.spdx.json` — SPDX

### License check

Fails the build if any dependency has a non-FOSS license or is missing
license metadata. The Oracle JavaCard SDK license is allowed via the
root-level `license-override.properties`:

```bash
mvn clean verify -Plicense-check
```

### GPG signing

Signs the JAR, `.cap`, and POM with your GPG key. You need to specify the key
fingerprint (find it with `gpg --list-secret-keys`):

```bash
mvn -Psign -Dgpg.key=YOUR_KEY_ID clean verify
```

Signature files (`*.asc`) are produced alongside the artifacts.
Verify them with:

```bash
gpg --verify target/javacard-hello-world-1.0-SNAPSHOT.jar.asc
gpg --verify target/010203040506.cap.asc
```

# Requirements

This project uses two separate Java compilers:

- **Main sources (applet code)** — compiled against Java 1.1 with a **JDK 8** `javac`, because recent JDKs (17+) reject the old `-target 1.1` option that JavaCards require. You must specify the path to your JDK 8 `javac` via `-Djava.compiler.main.path`.
- **Test sources** — compiled normally using whatever JDK is on your `$PATH` / `$JAVA_HOME` (Java 17+ recommended).

You can use any modern Java version for running tests and general development. Only the applet compilation step requires JDK 8.

> **Note:** If you increase the target version beyond 1.1, the resulting `.cap` file may not run on all JavaCards.

# Configuration

I have split the Maven configuration into three files:

- `pom.xml` for project-specific settings, plugins and dependencies.
- `parent-javacard.xml` for configuration related to all JavaCard projects.
- `parent-java.xml` for my general favorite Maven settings for Java projects.
  It also specifies the plugin versions and default configuration.

You **must** define these properties in your `pom.xml`:
- `<applet.id>` — JavaCard AID (e.g. `01:02:03:04:05:06`)
- `<applet.main.class>` — fully qualified applet class (e.g. `helloworld.HelloWorldApplet`)

`<applet.version>` is automatically derived from `<version>` by stripping any
qualifier (e.g. `1.0-SNAPSHOT` → `1.0`). You can still override it explicitly.

# Build

Before the first build, install the JavaCard SDK's `api_classic.jar` into your local
Maven repository. This is a one-time step:

```bash
mvn install:install-file \
  -Dfile=../../../external/oracle_javacard_sdks/jc305u4_kit/lib/api_classic.jar \
  -DgroupId=com.oracle.javacard -DartifactId=api-classic \
  -Dversion=3.0.5 -Dpackaging=jar
```

Then build the project:

```bash
mvn clean verify -Djava.compiler.main.path=/path/to/jdk8/bin/javac
```

The `-Djava.compiler.main.path` argument is **required** — the build will fail without it. This tells the compiler which JDK 8 `javac` to use for applet code.

To avoid passing it every time, persist it in `.mvn/maven.config`:

```bash
echo '-Djava.compiler.main.path=/path/to/jdk8/bin/javac' > .mvn/maven.config
```

# Software Bill of Materials (SBOM)

The project includes two SBOM generators (opt-in via `pom.xml`):

- **CycloneDX** (`org.cyclonedx:cyclonedx-maven-plugin`) — security-focused, excludes test dependencies.
  Output: `target/bom.json`
- **SPDX** (`org.spdx:spdx-maven-plugin`) — license/compliance-focused, includes all scopes.
  Output: `target/site/helloworld_javacard-applet-1.0-SNAPSHOT.spdx.json`

Both run during `mvn package` and produce JSON. Activate them with the `sbom` profile:

```bash
mvn clean package -Psbom
```

# Run single test

```bash
mvn test [-Dtest=TestClass#testMethod]
mvn failsafe:integration-test [-Dit.test=TestClass#testMethod]
```

# Signing

Artifacts can be signed with GPG using the `sign` profile. You must specify the key fingerprint via `-Dgpg.key`:

```bash
mvn -Psign -Dgpg.key=1234567890ABCDEF1234567890ABCDEF12345678 clean verify
```

Find your key fingerprint with `gpg --list-secret-keys`.

## Verify a signed release

Each release artifact (`.jar`, `.cap`, `.pom`) has a matching `.asc` signature file. To verify it's from the correct author:

```bash
gpg --verify javacard-applet-1.0.asc javacard-applet-1.0.cap
```

You need the author's public key imported. It can be downloaded from a key server:

```bash
gpg --keyserver keys.openpgp.org --recv-key 1234567890ABCDEF1234567890ABCDEF12345678
```

Replace the key ID with the one used for signing.

# Maintenance

Update dependency versions:

```bash
mvn versions:display-dependency-updates
mvn versions:display-plugin-updates
mvn versions:display-property-updates -DincludeParent
```

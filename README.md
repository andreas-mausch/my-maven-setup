# Table of Contents

- [About This Project](#about-this-project)
- [Decisions](#decisions)
- [Available Parent POMs](#available-parent-poms)
- [Requirements](#requirements)
- [Run tests](#run-tests)
  - [Run all tests](#run-all-tests)
  - [Run single test](#run-single-test)
  - [Test reports](#test-reports)
- [Software Bill of Materials (SBOM)](#software-bill-of-materials-sbom)
- [Vulnerability scanning](#vulnerability-scanning)
- [Code coverage](#code-coverage)
- [License check](#license-check)
- [Signing](#signing)
  - [Verify a signed release](#verify-a-signed-release)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)
- [Disclaimer](#disclaimer)

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

Choose your project type to get started:

- **Plain Java** → see [README-java.md](README-java.md)
- **JavaCard applet** → see [README-javacard.md](README-javacard.md)

# Decisions

This section documents design decisions and trade-offs made during the project.

## Why still Maven in 2026?

For Java and Kotlin, Maven is still the most stable and well-supported build tool I know. I've looked for better alternatives, but haven't found one yet. And I absolutely dislike Gradle.
You write a program to compile your program? That sounds like a bad concept to me.
And it shows when you try to upgrade to a newer Gradle version: Often there are
incompatibilities, you might have to rewrite a lot of your `build.gradle` and sometimes
a plugin doesn't work under the new version. I've also experienced that Gradle didn't
work with a newly released Java version and just declined to run the build at all.
This was fixed 1-3 weeks after the release, but still a blocker.

Then the Gradle Wrapper: Another flawed concept, and I think it mainly exists due to
the big incompatibility between Gradle versions. Following this concept, you
could use the same argument to have a JDK wrapper. Software should be installed
on the system by the user, in my opinion.

Then there is the Gradle Daemon, which doesn't improve the build speed at all. I always
get triggered when I see "subsequent builds will be faster". I know you can run it
without the daemon, but why is it still the default?

And for Maven: I know a Maven wrapper exists, but I don't use it and since the
`pom.xml`'s structure is fairly stable, newer Maven versions are usually able to run
older builds without any problems. I prefer to use the enforcer plugin to make sure the
user doesn't run an ancient Maven, but that's it. I like the plugin concept.

Of course, Maven is not perfect and feels old in a lot of places. And the huge XML files
are not easy to maintain. I would love YAML here, and I know there is Maven Polyglot,
but I'm not sure I want to use it yet.

# Available Parent POMs

The Maven configuration is split across three files:
- `pom.xml` in your project: project-specific settings, plugins, and dependencies.
- `parent-java.xml`: general Maven settings for Java projects; also specifies plugin versions and default configuration.
- `parent-javacard.xml`: configuration shared across all JavaCard projects.

| Parent POM            | Artifact                                   | Description                                                                                                                                                |
|-----------------------|--------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `parent-java.xml`     | `de.neonew:java-parent:1.0.0-SNAPSHOT`     | General Java: compiler, JAR, enforcer, surefire, failsafe, JaCoCo, git-commit-id, versions, GPG signing, CycloneDX/SPDX SBOM, license checks, shade plugin |
| `parent-javacard.xml` | `de.neonew:javacard-parent:1.0.0-SNAPSHOT` | JavaCard applet: extends `java-parent`, adds JDK 8 cross-compilation, ProGuard obfuscation, JCDK packaging, jCardSim for integration tests                 |

# Requirements

- **JDK 21+** for Maven and tests
- **JDK 8** (`javac`) for JavaCard applet compilation (only if using `parent-javacard.xml`)
  > ⚠️ The applet code is compiled against Java 1.1 (`-target 1.1`), which modern
  > JDKs reject. Only the applet compilation step requires JDK 8.
- **Maven 3.6+**

# Run tests

## Run all tests

```bash
mvn clean verify
```

This runs unit tests (via surefire) and integration tests (via failsafe) with code coverage (via JaCoCo).

## Run single test

```bash
mvn test [-Dtest=TestClass#testMethod]
mvn failsafe:integration-test [-Dit.test=TestClass#testMethod]
```

## Test reports

After running tests, you'll find these reports in `target/`:

| Artifact            | Description                 |
|---------------------|-----------------------------|
| `surefire-reports/` | Unit test reports           |
| `failsafe-reports/` | Integration test reports    |
| `site/jacoco/`      | JaCoCo code coverage report |

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

# Code coverage

Code coverage is measured with [JaCoCo](https://www.jacoco.org/jacoco/). It is configured in
the parent POM and can be activated with the `coverage` profile:

```bash
mvn clean verify -Pcoverage
```

Coverage data is collected during tests and a report is generated in
`target/site/jacoco/`. A summary is also printed to the console after each build.

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
gpg --verify my-artifact-1.0.asc my-artifact-1.0.jar
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

# Troubleshooting

You may see the following warnings during builds. They are harmless and can be
safely ignored:

## CycloneDX: Unknown keyword `meta:enum` / `deprecated`

```
[WARNING] Unknown keyword meta:enum - you should define your own Meta Schema.
[WARNING] Unknown keyword deprecated - you should define your own Meta Schema.
```

These come from the CycloneDX Maven plugin validating its JSON schema against a
library that does not recognize the `meta:enum` and `deprecated` keywords.
The plugin authors are aware of this — it does not affect the generated SBOM.
See [cyclonedx/cyclonedx-maven-plugin#564](https://github.com/CycloneDX/cyclonedx-maven-plugin/issues/564).

## SPDX: Reflective final field mutation

```
WARNING: Final field licenses in class org.spdx.storage.listedlicense.LicenseJsonTOC has been mutated reflectively by class com.google.gson.internal.bind.ReflectiveTypeAdapterFactory$1 in unnamed module @...
WARNING: Use --enable-final-field-mutation=ALL-UNNAMED to avoid a warning
```

The SPDX Maven plugin uses Gson to mutate a `final` field via reflection.
This is a JVM 21+ warning and will become an error in a future release. It does not affect functionality.

# Disclaimer

This project was created using AI (opencode, Big Pickle, Qwen3.6).

It is one of my first experiments with coding AI agents and also a learning experiment for me.
I can recommend running Qwen3.6 locally.
I have used the exact model Qwen3.6-35B-A3B (Q4_K_M) on my gaming PC
(4070 Ti 12 GB VRAM, 64 GB DDR4) and get around 30 tokens/sec with a context length of 65536.

# Shared Build Features

This document covers features shared by projects that use `java-parent`, `kotlin-parent`, or `javacard-parent`. Run the
commands in the root directory of a consumer project, such as one of the projects under `examples/`, not in this
repository's root.

## Run Tests

The parent POMs support both unit and integration tests with separate Maven lifecycle phases.

### Unit tests

Unit tests run through Surefire during the `test` phase. Surefire excludes tests in packages containing `.integration.`,
keeping them out of unit-test runs.

Run all unit tests without integration tests:

```bash
mvn test
```

### Integration tests

Failsafe includes tests in packages containing `.integration.` and runs them during the `integration-test` and `verify`
phases.

Consumer POMs must activate the inherited Failsafe and Build Helper plugin configurations. Build Helper registers the
additional integration-test sources and resources; Failsafe executes and verifies the tests.

### Run all tests

```bash
mvn clean verify
```

This runs both unit and integration tests. Optional features such as code coverage, SBOM generation, license checks,
formatting checks, and signing run only when their respective profiles are active.

### Run a single test

```bash
mvn test -Dtest=TestClass#testMethod
mvn test-compile failsafe:integration-test failsafe:verify -Dit.test=TestClass#testMethod
```

### Test reports

After running tests, these reports are available under `target/`:

| Artifact            | Description                                               |
|---------------------|-----------------------------------------------------------|
| `surefire-reports/` | Unit test reports                                         |
| `failsafe-reports/` | Integration test reports                                  |
| `site/jacoco/`      | Coverage report when the `coverage` profile is active     |

## Integration Tests with Real Infrastructure

Integration tests run against real infrastructure services such as databases and message brokers instead of mocking
their behavior. For Micronaut projects, Micronaut Test Resources provisions these services with
[Testcontainers](https://testcontainers.com/).

## Versioned Database Migrations

Database changes can be applied as versioned migrations before the application starts.
This makes the changes reproducible and keeps the database consistent with the application version.

The Kotlin Micronaut example uses [Mongock](https://www.mongock.io/). It records completed migrations and uses a
distributed lock so that each migration runs only once, even when multiple application instances start concurrently.

## Generated API Documentation

Micronaut projects can generate an OpenAPI specification from their controllers and API models at compile time.
This keeps the API description consistent with the implementation.

The Kotlin Micronaut example serves interactive [RapiDoc](https://rapidocweb.com/) documentation at `/docs` and the
generated OpenAPI specification at `/docs/spec/openapi.yaml`.

## Application Health

Micronaut projects can expose application health, liveness, and readiness through Micronaut Management.
The Kotlin Micronaut example provides `/health`, `/health/liveness`, and `/health/readiness` and excludes regular health
probes from its HTTP access log.

## Container Image

The Kotlin Micronaut example provides a production-oriented Dockerfile based on a Java runtime image.
The container runs as a non-root user and includes a health check against the application's liveness endpoint.

## Request Validation

Micronaut projects can validate incoming request models with Jakarta Bean Validation before executing application
logic. The Kotlin Micronaut example rejects subscriptions with a blank order ID as a bad request.

## Offline Builds and External API Simulation

All calls to external HTTP APIs can be simulated during integration tests.
This removes dependencies on live external systems and makes the tests deterministic.

The simulations use [WireMock](https://wiremock.org/).
Once all Maven dependencies and required container images are available locally, the complete build, including its
integration tests, can run without network access.

## Software Bill of Materials

The project includes two SBOM generators, activated through the `sbom` profile:

- **CycloneDX** (`org.cyclonedx:cyclonedx-maven-plugin`): security-focused and excludes test dependencies. Output:
  `target/{finalName}.sbom.cyclonedx.json`.
- **SPDX** (`org.spdx:spdx-maven-plugin`): license- and compliance-focused and includes all scopes. Output:
  `target/{finalName}.sbom.spdx.json`.

Both run during `package` and produce JSON:

```bash
mvn clean package -Psbom
```

## Vulnerability Scanning

Scan the generated CycloneDX SBOM with [Grype](https://github.com/anchore/grype):

```bash
grype sbom:target/{finalName}.sbom.cyclonedx.json --fail-on high
```

## Code Coverage

Activate [JaCoCo](https://www.jacoco.org/jacoco/) with the `coverage` profile:

```bash
mvn clean verify -Pcoverage
```

Coverage data is collected during tests, an HTML report is generated in `target/site/jacoco/`, and a summary is printed
to the console during `verify`.

## Executable Application JARs

Java and Kotlin projects can produce an executable shaded (fat) JAR containing the application and all runtime
dependencies.

The shaded JAR is the main Maven artifact and can be started directly with `java -jar`. Its file name includes the Git
description to make the built revision identifiable.

## Size Optimization

Activate size optimization with the `size-optimization` profile:

```bash
mvn clean package -Psize-optimization
```

For Java and Kotlin projects, this removes unused code and applies further bytecode optimizations to the executable
shaded JAR described above, including its bundled dependencies. The optimized result is attached as
`target/<artifactId>-<git-description>-proguard.jar`; the shaded JAR remains the main Maven artifact. The inherited
`main.class` property must identify the application's entry point so that it is preserved.

For JavaCard projects, unused bytecode is removed before JCDK packages the compiled classes into the CAP file, reducing
the applet's footprint. JavaCard builds still require the JDK 8 compiler and JavaCard SDK properties described in
[README-javacard.md](README-javacard.md).

The current implementation uses [ProGuard](https://www.guardsquare.com/proguard), which also obfuscates names as part of
its processing. Obfuscation is not the primary purpose of this feature. Projects using reflection, dependency injection,
serialization, native methods, or additional Java modules may need project-specific ProGuard keep rules or library
entries.

## License Check

Enforce that all dependencies have known licenses from the configured allowlist with the `license-check` profile:

```bash
mvn clean verify -Plicense-check
```

The build fails if a dependency has a license outside the allowlist or is missing license metadata. License aliases and
the default FOSS allowlist are defined in `parent-java.xml` under `<licenseMerges>` and `<includedLicenses>`.
`parent-javacard.xml` adds the proprietary Oracle JavaCard SDK license as an explicit exception and obtains its metadata
from `maven-build-config`.

## Signing

Sign project artifacts with GPG by activating the `sign` profile and specifying the key fingerprint through
`-Dgpg.key`:

```bash
mvn -Psign -Dgpg.key=1234567890ABCDEF1234567890ABCDEF1234567890 clean verify
```

Find the fingerprint with `gpg --list-secret-keys`.

### Verify signed project artifacts

When a consumer project is built with the `sign` profile, its POM and each generated or attached project artifact, such
as a JAR or CAP file, have matching `.asc` signatures. Verify that an artifact was signed with the expected key:

```bash
gpg --verify my-artifact-1.0.asc my-artifact-1.0.jar
```

The author's public key must be imported first. It can be downloaded from a key server:

```bash
gpg --keyserver keys.openpgp.org --recv-key 1234567890ABCDEF1234567890ABCDEF1234567890
```

Replace the fingerprint with the one used for signing.

## Maintenance

Display available dependency, plugin, and property updates:

```bash
mvn versions:display-dependency-updates
mvn versions:display-plugin-updates
mvn versions:display-property-updates -DincludeParent
```

## Code Formatting

[Spotless](https://github.com/diffplug/spotless) uses the Eclipse JDT formatter for Java, ktfmt for Kotlin, and the
Eclipse WTP formatter for POM files. It also removes unused Java imports and enforces trailing-whitespace and end-of-file
rules. Formatting checks run only when the `linting` profile is active.

Check formatting:

```bash
mvn clean verify -Plinting
```

Apply formatting:

```bash
mvn spotless:apply -Plinting
```

## Pre-commit Hook

The hook in `githooks/pre-commit` is a template for projects that use one of these parent POMs. It checks the complete
consumer project, does not modify files, and rejects the commit if Spotless finds formatting violations.

Copy the `githooks` directory into the consumer project and activate it there:

```bash
git config core.hooksPath githooks
```

## Troubleshooting

### CycloneDX: Unknown keyword `meta:enum` or `deprecated`

```text
[WARNING] Unknown keyword meta:enum - you should define your own Meta Schema.
[WARNING] Unknown keyword deprecated - you should define your own Meta Schema.
```

These warnings come from the CycloneDX Maven plugin validating its JSON schema against a library that does not
recognize the `meta:enum` and `deprecated` keywords. The plugin authors are aware of them, and they do not affect the
generated SBOM. See
[cyclonedx/cyclonedx-maven-plugin#564](https://github.com/CycloneDX/cyclonedx-maven-plugin/issues/564).

### SPDX: Reflective final field mutation

```text
WARNING: Final field licenses in class org.spdx.storage.listedlicense.LicenseJsonTOC has been mutated reflectively by class com.google.gson.internal.bind.ReflectiveTypeAdapterFactory$1 in unnamed module @...
WARNING: Use --enable-final-field-mutation=ALL-UNNAMED to avoid a warning
```

The SPDX Maven plugin uses Gson to mutate a `final` field through reflection. This is a JVM 21+ warning and will become
an error in a future Java release. It does not currently affect functionality.

# Shared Build Features

This document covers features shared by projects that use `java-parent`, `kotlin-parent`, `kotlin-micronaut-parent`, or
`javacard-parent`. Run the commands in the root directory of a consumer project, such as one of the projects under
`examples/`, not in this repository's root.

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

Surefire writes its canonical unit test results to `target/surefire-reports/`. Failsafe writes the corresponding
integration test results to `target/failsafe-reports/`.

## Compiler Warnings

Java and Kotlin compiler warnings fail the build by default. Set `<fail.on.warning>false</fail.on.warning>` in the
consumer POM only when a warning cannot be fixed or suppressed more narrowly.

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
  `target/<artifactId>-<version>.sbom.cyclonedx.json`.
- **SPDX** (`org.spdx:spdx-maven-plugin`): license- and compliance-focused and includes all scopes. Output:
  `target/<artifactId>-<version>.sbom.spdx.json`.

Both run during `package` and produce JSON:

```bash
mvn clean package -Psbom
```

## Vulnerability Scanning

Scan the generated CycloneDX SBOM with [Grype](https://github.com/anchore/grype):

```bash
grype "sbom:target/<artifactId>-<version>.sbom.cyclonedx.json" --fail-on high
```

## Code Coverage

Activate [JaCoCo](https://www.jacoco.org/jacoco/) with the `coverage` profile:

```bash
mvn clean verify -Pcoverage
```

Coverage data is collected during tests, the multi-file HTML report is written to
`target/reports/coverage/`, and a summary is printed to the console during `verify`.

## Executable Application JARs

Java and Kotlin projects can produce an executable shaded (fat) JAR containing the application and all runtime
dependencies.

The shaded JAR is the main Maven artifact, uses Maven's standard `<artifactId>-<version>.jar` file name, and can be
started directly with `java -jar`.

## Size Optimization

Activate size optimization with the `size-optimization` profile:

```bash
mvn clean package -Psize-optimization
```

For the Java and Kotlin examples, ProGuard removes unused code, optimizes the remaining bytecode, and obfuscates names
in the executable shaded JAR described above, including its bundled dependencies. The result is attached as
`target/<artifactId>-<version>-proguard.jar`; the shaded JAR remains the main Maven artifact. The inherited `main.class`
property must identify the application's entry point so that it is preserved.

The Kotlin Micronaut parent disables optimization and obfuscation with `-dontoptimize` and `-dontobfuscate` because
Micronaut and its integrations rely on generated classes, bean and serialization metadata, service indexes, and dynamic
class lookups. Preserving class names and bytecode structure avoids invalidating those links at runtime. Combined with
Micronaut-specific keep rules, the `size-optimization` profile therefore safely removes only unused code from the shaded
JAR.

For JavaCard projects, unused bytecode is removed before JCDK packages the compiled classes into the CAP file, reducing
the applet's footprint. JavaCard builds still require the JDK 8 compiler and JavaCard SDK properties described in
[README-javacard.md](README-javacard.md).

The current implementation uses [ProGuard](https://www.guardsquare.com/proguard). Projects using reflection, dependency
injection, serialization, native methods, or additional Java modules may need project-specific ProGuard keep rules or
library entries.

## License Check

Enforce that all dependencies have known licenses from the configured allowlist with the `license-check` profile:

```bash
mvn clean verify -Plicense-check
```

The build fails if a dependency has a license outside the allowlist or is missing license metadata. License aliases and
the default FOSS allowlist are defined in `parent-java.xml` under `<licenseMerges>` and `<includedLicenses>`.

`parent-javacard.xml` adds the proprietary Oracle JavaCard SDK license as an explicit exception and obtains its metadata
from `maven-build-config`.

## Reports

The build generates the following reports for people to inspect:

| Report                                             | Description                                           | Template                                                    |
|----------------------------------------------------|-------------------------------------------------------|-------------------------------------------------------------|
| `target/reports/tests-unit.html`                   | Self-contained, searchable unit test report           | [XSLT template][test-report-template]                        |
| `target/reports/tests-integration.html`            | Self-contained, searchable integration test report    | [XSLT template][test-report-template]                        |
| `target/reports/coverage/`                         | Coverage report when the `coverage` profile is active |                                                             |
| `target/generated-sources/license/THIRD-PARTY.txt` | Plain-text dependency license summary                 |                                                             |
| `target/reports/dependency-licenses.html`          | Self-contained, searchable dependency license report  | [FreeMarker template][dependency-license-report-template]   |
| `target/reports/vulnerabilities-dependencies.html` | Self-contained, searchable Grype dependency report    | [Grype template][vulnerability-report-template]             |
| `target/reports/vulnerabilities-container.html`    | Self-contained, searchable Grype container report     | [Grype template][vulnerability-report-template]             |

[test-report-template]: maven-build-config/src/main/resources/de/neonew/maven/test-report.xsl
[dependency-license-report-template]: maven-build-config/src/main/resources/de/neonew/maven/dependency-license-report.ftl
[vulnerability-report-template]: maven-build-config/src/main/resources/de/neonew/maven/vulnerability-report.tmpl

The internal `test-report` profile is activated automatically for every project whose packaging is not `pom`. It
generates the unit and integration test HTML reports after Surefire and Failsafe have run. Consumers do not need to
activate the profile with `-P`; projects without the corresponding test results receive an empty report rather than
failing the build.

The `license-check` profile generates both dependency license reports. `THIRD-PARTY.txt` uses a plugin-specific
plain-text format with one dependency per line: license, project name, Maven coordinates, and project URL.

The optional `vulnerability-report` profile requires `grype` on `PATH`. It renders the dependency report from the
canonical CycloneDX SBOM during `verify`:

```bash
mvn clean verify -Psbom,vulnerability-report
```

Container reports are generated explicitly after building the image:

```bash
mvn -Pvulnerability-report \
  -Dvulnerability.report.container.source=<image> \
  initialize exec:exec@generate-container-vulnerability-report
```

The report timestamp uses the Maven build time. Its format and time zone can be configured with
`build.reports.timestamp.format` and `build.reports.timestamp.timezone`. Report generation and vulnerability policy
checks are separate so the reports remain available even when a policy check fails.

```text
(Apache 2) AssertJ fluent assertions org.assertj:assertj-core:3.27.7 - https://assertj.github.io/doc/
```

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
gpg --verify my-artifact-1.0.jar.asc my-artifact-1.0.jar
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

### SPDX: Unknown relationship type for `provided` dependencies

```text
[WARNING] Could not determine the SPDX relationship type for dependency artifact ID <artifactId> scope provided
```

The SPDX Maven plugin does not map Maven's `provided` scope to a specific SPDX relationship type. The dependency is
still included and the generated document remains valid, but its relationship is classified as `OTHER`. This upstream
limitation affects all non-optional `provided` dependencies. See
[spdx/spdx-maven-plugin#213](https://github.com/spdx/spdx-maven-plugin/issues/213).

### SPDX: Reflective final field mutation

```text
WARNING: Final field licenses in class org.spdx.storage.listedlicense.LicenseJsonTOC has been mutated reflectively by class com.google.gson.internal.bind.ReflectiveTypeAdapterFactory$1 in unnamed module @...
WARNING: Use --enable-final-field-mutation=ALL-UNNAMED to avoid a warning
```

The SPDX Maven plugin uses Gson to mutate a `final` field through reflection. This is a JVM 21+ warning and will become
an error in a future Java release. It does not currently affect functionality.

### KSP: Terminally deprecated `sun.misc.Unsafe` method

```text
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by ksp.com.intellij.util.containers.Unsafe (.../symbol-processing-aa-embeddable-2.3.11.jar)
WARNING: Please consider reporting this to the maintainers of class ksp.com.intellij.util.containers.Unsafe
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
```

KSP's embedded IntelliJ code calls a terminally deprecated JDK method. The warning occurs on JDK 25 and does not
currently affect code generation, but KSP must replace the call before the method is removed from a future JDK. See
[google/ksp#2753](https://github.com/google/ksp/issues/2753).

### Micronaut OpenAPI: Experimental compile-time resource contribution

```text
[INFO] [ksp:main] EXPERIMENTAL: Compile time resource contribution to the context is experimental
```

`io.micronaut.openapi:micronaut-openapi:7.1.3` emits this message when it registers the generated OpenAPI document as a
classpath resource through an API deprecated by `io.micronaut:micronaut-core-processor:5.1.15`. The API is no longer
used, but its default implementation still logs this message for every call. The OpenAPI document is generated
correctly, and the message does not indicate a build or application problem.

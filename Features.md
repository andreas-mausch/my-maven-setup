# Shared Build Features

This document covers features shared by projects that use `java-parent`, `kotlin-parent`, `kotlin-micronaut-parent`, or
`javacard-parent`. Run the commands in the root directory of a consumer project, such as one of the projects under
`examples/`, not in this repository's root.

## Reproducible Builds

Rebuilding a release with the same sources and build environment should produce identical JAR files. The parent
POMs support this for the main JVM JAR and the optional `-proguard.jar` produced with `size-optimization`.

Archive timestamps are taken from the Git commit automatically, rather than the time of the build. No additional
profile or command-line option is required.

Builds without Git are supported when you supply a stable timestamp through `project.build.outputTimestamp`,
either in your POM or on the command line. Use the original commit or release timestamp in UTC ISO-8601 format
ending in `Z` (epoch seconds and timezone offsets are not accepted), for example:

```bash
mvn -Dproject.build.outputTimestamp=2026-11-17T00:00:00Z clean package
```

Without Git or an explicit timestamp, the build fails with an explanatory message. Use the same timestamp for every
rebuild of that release, not the current time.

Reproducibility also requires identical sources, Git metadata, dependencies, Maven and JDK versions. To verify a
rebuild, compare the JARs' SHA-256 hashes. A stable timestamp alone does not guarantee identical artifacts across
different toolchains or dependencies.

JavaCard CAP files also support reproducible builds, with or without `size-optimization`.
Use the same `project.build.outputTimestamp` value for each rebuild; different textual representations of the same
instant can produce different CAP files. CycloneDX and SPDX JSON SBOMs generated with `sbom` were also verified
byte-identical under the same requirements and matching profiles. Container images, reports and detached GPG
signatures are not covered.
See [ADR-0029](docs/decisions/0029-build-reproducibility.md) for the implementation decisions and current scope.

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

To retain the complete build output with ANSI formatting while continuing to display it in the terminal, run the build
through `tee`:

```bash
mvn -Dstyle.color=always clean verify 2>&1 | tee maven-build.log
```

The log is written to the project root rather than `target` because the `clean` phase removes that directory during the
build. CI enables `pipefail` separately so that a Maven failure is not hidden by a successful `tee` process.

Display the ANSI colors correctly with `bat` by treating the log as plain text:

```bash
bat --map-syntax='*.log:Plain Text' maven-build.log
```

CI stores this ANSI-formatted original as `maven-build.log` and additionally provides an ANSI-stripped
`maven-build-plain.log` for tools that do not interpret terminal formatting.

### Run a single test

```bash
mvn test -Dtest=TestClass#testMethod
mvn test-compile failsafe:integration-test failsafe:verify -Dit.test=TestClass#testMethod
```

### Test reports

Surefire writes its canonical unit test results to `target/surefire-reports/`. Failsafe writes the corresponding
integration test results to `target/failsafe-reports/`.
The HTML test reports support substring search, CamelCase abbreviations such as `MFT` for
`MyFeatureTest`, and wildcards such as `My*Test`.

`mvn verify` generates `target/reports/index.html` after the other build reports. Only existing reports are linked.
Keep the entire `target/reports/` directory together for offline use.

After generating additional reports outside the build, refresh the index:

```bash
mvn git-commit-id:revision xml:transform@generate-report-index
```

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

After building the image, consumer CI invokes Maven, which uses [Syft](https://github.com/anchore/syft)
to generate a CycloneDX 1.6 JSON SBOM of the final image filesystem (`squashed` scope).
The CI artifact includes `target/<artifactId>-<version>.container.sbom.cyclonedx.json` and a matching
`.container.image-id.txt` containing the immutable local image ID (config digest, not a registry manifest digest).
Published images should instead be associated with their registry digest. Both the Grype container report and
the CI vulnerability scan consume this container SBOM.
CI installs Syft with a pinned version and checksum; local use requires Syft and Grype on `PATH`.

## Request Validation

Micronaut projects can validate incoming request models with Jakarta Bean Validation before executing application
logic. The Kotlin Micronaut example rejects subscriptions with a blank order ID as a bad request.

## HTTP Problem Details

The Kotlin Micronaut example returns errors processed by Micronaut as `application/problem+json`. This standardized
format is compatible with [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457.html) and provides clients with structured
problem details such as the HTTP status and a short title. The integration tests verify the format for request validation
errors.

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

The separate container SBOM generated in consumer CI also inventories detected OS packages, the Java runtime and
application components. It complements rather than replaces the Maven SBOMs: detection of dependencies inside
shaded or optimized JARs may be incomplete.

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

Open `target/reports/coverage.html` for a self-contained report you can use offline or share as one file. It includes
a searchable source-file overview and source code with line coverage. JaCoCo's XML and CSV outputs remain at
`target/reports/coverage/`; no additional JaCoCo HTML report is generated. A coverage summary is also printed during `verify`.

Search uses full file paths and is case-insensitive. Without `*`, it matches word prefixes; CamelCase searches such as
`UserCon` match ordered prefixes within the same path word, not across directories and filenames. With `*`, the search
matches the full path using `*` as a wildcard, for example `User*Controller` or `directory/*`. Other characters are
literal; use a wildcard for directory searches.

Sources must be available in Maven's registered main source directories when the report is generated. Standard Java
and Kotlin directories are already covered; register any additional directories with Maven, including custom Kotlin
`sourceDirs`. **Source root paths must not contain commas**. Unavailable sources still show their coverage counts.

The report contains source code, so review it before publishing. If no coverage data is collected, no new standalone
report is generated; use `clean` to avoid stale reports.

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

The optimized JVM JAR uses the same reproducible-build timestamp as the main JAR. Backup and patch files
(`*~`, `*.bak`, `*.orig`, `*.rej`) are excluded. See [Reproducible Builds](#reproducible-builds) for requirements
and [ADR-0029](docs/decisions/0029-build-reproducibility.md) for implementation decisions.

The Kotlin Micronaut parent disables optimization and obfuscation with `-dontoptimize` and `-dontobfuscate` because
Micronaut and its integrations rely on generated classes, bean and serialization metadata, service indexes, and dynamic
class lookups. Preserving class names and bytecode structure avoids invalidating those links at runtime. Combined with
Micronaut-specific keep rules, the `size-optimization` profile therefore safely removes only unused code from the shaded
JAR.

For JavaCard projects, unused bytecode is removed before JCDK packages the compiled classes into the CAP file, reducing
the applet's footprint. JavaCard builds still require the JDK 8 compiler and JavaCard SDK properties described in
[README-javacard.md](README-javacard.md).
JavaCard does not produce a separate `-proguard.jar`; the optimized classes are used for CAP generation.
ProGuard runs only with `size-optimization`, not in every CAP build. Both normal and optimized CAP files support
reproducible builds under the requirements described above.

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
| `target/reports/tests-unit.html`                   | Self-contained, searchable unit test report           | [XSLT template][test-report-template]                       |
| `target/reports/tests-integration.html`            | Self-contained, searchable integration test report    | [XSLT template][test-report-template]                       |
| `target/reports/coverage.html`                     | Self-contained, searchable source coverage report     | [XSLT template][coverage-report-template]                   |
| `target/reports/coverage/`                         | JaCoCo XML and CSV coverage data                      |                                                             |
| `target/reports/THIRD-PARTY.txt`                   | Plain-text dependency license summary                 |                                                             |
| `target/reports/dependency-licenses.html`          | Self-contained, searchable dependency license report  | [FreeMarker template][dependency-license-report-template]   |
| `target/reports/vulnerabilities-dependencies.html` | Self-contained, searchable Grype dependency report    | [Grype template][vulnerability-report-template]             |
| `target/reports/vulnerabilities-container.html`    | Self-contained, searchable Grype container report     | [Grype template][vulnerability-report-template]             |

[test-report-template]: maven-build-config/src/main/resources/de/neonew/maven/test-report.xsl
[coverage-report-template]: maven-build-config/src/main/resources/de/neonew/maven/coverage-report.xsl
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
  initialize exec:exec@generate-container-sbom exec:exec@generate-container-vulnerability-report
```

The report timestamp uses the Maven build time. Its format and time zone can be configured with
`build.reports.timestamp.format` and `build.reports.timestamp.timezone`. Report generation and vulnerability policy
checks are separate so the reports remain available even when a policy check fails.
Both vulnerability reports record the Grype version and the scanned database's schema version and build timestamp.
The database archive's SHA-256 checksum is included when available in Grype's database source URL. These metadata
identify the database used for the scan; database updates remain enabled as configured in Grype.

### Temporary container vulnerability exceptions

The container report optionally reads `security/container-vulnerability-exceptions.toml` in the consuming
project. The container scan wrapper requires **Python >= 3.11**, using only standard libraries:
`tomllib`, `datetime`, `json`, file utilities and `subprocess`. No pip packages, yq or shell are needed.
Without the optional TOML file, Grype runs without exception configuration.
The generated `.grype.yaml` contains JSON, which is valid YAML and accepted by Grype.
The parent defaults to `python3`; override `vulnerability.report.python.executable` with the Python
executable name or path on your platform (for example `python` on Windows).

A commented, empty [TOML template](maven-build-config/src/main/resources/de/neonew/maven/container-vulnerability-exceptions.toml)
is shipped with `maven-build-config` and extracted by `initialize`. Copy it explicitly into your project:

```bash
mvn -Pvulnerability-report initialize
mkdir -p security
cp -i target/vulnerability-report/de/neonew/maven/container-vulnerability-exceptions.toml \
  security/container-vulnerability-exceptions.toml
```

The build never creates or overwrites the project's exception input automatically.

```toml
exceptions = [
  # Replace the date and scope with an explicitly approved, current acceptance.
  # { cve = "CVE-2026-95692", package = "libcrypto3", version = "3.5.9-r0", expires = "2026-12-02", reason = "Approved pending upstream backport" }
]
```

Each entry needs a non-blank reason and a quoted UTC `YYYY-MM-DD` expiry. Expiry is exclusive
(the start of that day), must be in the future and may be at most 30 days away when validated.
Invalid or expired files fail validation. Prefer CVE rules scoped to an exact APK package version;
omit both `package` and `version` for a CVE-wide rule, or omit `cve` for a package-version rule.
Unscoped rules and wildcard versions are forbidden. Approvals belong in Git, not pipeline variables;
remove rules once fixes become available.

The Maven command above validates automatically before the container scan. Override paths with
`vulnerability.report.container.exceptions` (input) and `vulnerability.report.container.exceptions.config`
(generated YAML). By default, audit outputs are `${project.build.directory}/container-vulnerability-exceptions.grype.yaml`
and a copy named `container-vulnerability-exceptions.toml` beside that YAML. Keep outputs separate from inputs.
The HTML Accepted view shows the rules and accepted findings separately from open severity totals.
Dependency scans and existing CI warning/blocking policies are unchanged.

For CI preparation or a direct scan, use the validator extracted by `initialize`:

```bash
python3 target/vulnerability-report/de/neonew/maven/prepare-container-exceptions.py \
  security/container-vulnerability-exceptions.toml target/container-vulnerability-exceptions.grype.yaml

python3 target/vulnerability-report/de/neonew/maven/prepare-container-exceptions.py --scan \
  security/container-vulnerability-exceptions.toml target/container-vulnerability-exceptions.grype.yaml \
  sbom:target/my-app.container.sbom.cyclonedx.json --fail-on high
```

CI may validate once in a preparation job and forward the YAML to Grype's `--config` option in the
later container scan. Direct Grype calls do not read TOML. Consumers must retain both audit outputs
with reports and, where appropriate, release bundles; this parent does not configure CI retention.
See [ADR-0030](docs/decisions/0030-container-vulnerability-exceptions.md).

Validator regression checks: `python3 maven-build-config/src/test/python/test_container_exceptions.py`
(requires Python >= 3.11 only; mocks the Grype invocation, no image or database downloads).
The consumer CI runs these checks against the validator extracted from the packaged build-config artifact
and runs the Micronaut container report and enforcement scan with an empty exception file. No findings
are accepted by this CI fixture; the generated configuration and TOML audit copy are uploaded with its artifacts.
Separately, an isolated vulnerable Log4j SBOM and a dynamically dated test exception verify real Grype
matching and the Accepted report view. That exception never applies to the application image; its test
inputs and outputs are uploaded separately for diagnosis.
The exception fixture lives in
[`examples/kotlin-micronaut/src/test/resources/container-vulnerability-exceptions.toml`](examples/kotlin-micronaut/src/test/resources/container-vulnerability-exceptions.toml);
CI substitutes its expiry placeholder without modifying the versioned file.

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

[Spotless](https://github.com/diffplug/spotless) uses the Eclipse JDT formatter for Java, ktlint for Kotlin, and the
Eclipse WTP formatter for POM files. It also removes unused Java imports and enforces trailing-whitespace and end-of-file
rules. Formatting checks run only when the `linting` profile is active.

The repository's suggested Kotlin style uses ktlint's IntelliJ-style rules with two-space indentation, LF line endings,
and no trailing commas.
There is no enforced line-length limit. Class and function signature layout rules are disabled to preserve
compact Kotest superclass calls and deliberately chosen expression-body line breaks. Spacing, import ordering,
unused imports, and the remaining standard rules are still checked.

The parent loads fallback settings from `ktlint.editorconfig` in the `maven-build-config` artifact through
Spotless's `editorConfigPath`. ktlint discovers consumer `.editorconfig` files normally and gives their settings
precedence over these defaults. No files are copied into the consumer project. For example, change only indentation:

```editorconfig
root = true

[*.{kt,kts}]
indent_size = 4
```

Other settings retain the parent defaults. `root = true` stops directory-based inheritance but does not remove
ktlint's fallback settings. Set `version.ktlint` to select another ktlint version, or `spotless.ktlint.file` to
replace the fallback configuration. For IDE consistency, declare the desired settings in the project's file;
IntelliJ does not read defaults from Maven artifacts.

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

See [Troubleshooting.md](Troubleshooting.md) for explanations of known messages emitted by the build tools.

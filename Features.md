# Shared Build Features

This document covers features shared by projects that use `java-parent`, `kotlin-parent`, or `javacard-parent`. Run the
commands in the root directory of a consumer project, such as one of the projects under `examples/`, not in this
repository's root.

## Run Tests

### Run all tests

```bash
mvn clean verify
```

This runs unit tests via Surefire. Integration tests run via Failsafe when the consumer POM activates the inherited
Failsafe and Build Helper plugin configurations. Optional features such as code coverage, SBOM generation, license
checks, formatting checks, and signing run only when their respective profiles are active.

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

## Software Bill of Materials

The project includes two SBOM generators, activated through the `sbom` profile:

- **CycloneDX** (`org.cyclonedx:cyclonedx-maven-plugin`): security-focused and excludes test dependencies. Output:
  `target/bom.json`.
- **SPDX** (`org.spdx:spdx-maven-plugin`): license- and compliance-focused and includes all scopes. Output:
  `target/site/{project-name}-{version}.spdx.json`.

Both run during `package` and produce JSON:

```bash
mvn clean package -Psbom
```

## Vulnerability Scanning

Scan the generated CycloneDX SBOM with [Grype](https://github.com/anchore/grype):

```bash
grype sbom:target/bom.json --fail-on high
```

## Code Coverage

Activate [JaCoCo](https://www.jacoco.org/jacoco/) with the `coverage` profile:

```bash
mvn clean verify -Pcoverage
```

Coverage data is collected during tests, an HTML report is generated in `target/site/jacoco/`, and a summary is printed
to the console during `verify`.

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

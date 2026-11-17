---
status: accepted
date: 2026-11-17
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0029: Build reproducibility

> Standard and optimized JAR packaging and CAP normalization are implemented; other outputs remain under evaluation.

## Context

Reproducibility means that identical sources, dependencies, toolchains and build timestamp values produce byte-identical
JARs and CAPs, independently of build time, resource modification times and timezone. Parent POMs and the standalone
`maven-build-config` module are out of scope.

## Decision

- Enable `reproducible-build` automatically for non-POM consumers. Set `project.build.outputTimestamp` to the
  Git commit time in ISO-8601 UTC; allow explicit stable UTC ISO-8601 overrides ending in `Z`. Reject epoch seconds
  and timezone offsets. Support reproducible
  builds for non-Git projects when they supply a stable timestamp. Reproducibility requires identical
  `project.build.outputTimestamp` property values. Reject missing or unresolved timestamps before packaging.
- Make standard and shaded JVM JARs, optional optimized `-proguard.jar` artifacts, and normal and optimized CAPs
  reproducible. Keep `size-optimization` optional and preserve runtime resources and CAP component bytes.
- Use temporary workarounds: ProGuard directory processing followed by Maven JAR packaging, and CAP timestamp
  normalization through Maven Assembly/Maven Archiver.
- Verify reproducibility manually with matching clean builds and SHA-256 comparisons; do not add extra CI builds.

### Follow-ups

- Adopt native ProGuard reproducibility and remove the JAR packaging workaround when [upstream support][1] is available.
- Adopt native Oracle converter reproducibility and remove CAP normalization when available.
- Evaluate the unchecked outputs listed in the artifact overview separately before claiming reproducibility.

## Consequences

- **Positive:** Consumers need no additional profile or Git checkout if they supply a stable release timestamp.
  Standard and optimized JARs and CAPs can be compared byte-for-byte without changing optimization policies.
- **Negative:** Both workarounds add extraction, intermediate directories and I/O. CAP normalization modifies a
  completed archive and intentionally replaces a temporary attachment, producing an
  [expected Maven warning](../../Troubleshooting.md#javacard-cap-artifact-already-attached).
- **Risks / neutral:** Reproducibility is limited to identical inputs and toolchains. Manual checks do not make CI
  detect reproducibility regressions. Valid signatures on reproducible artifacts do not imply reproducible signatures.

## Options considered

### Standard JARs

| Option | Verdict | Why |
|--------|---------|-----|
| Git commit timestamp with explicit stable overrides | ✅ | Reflects the source revision and supports consumers without Git |
| Fixed overridable timestamp | ❌ | Deterministic, but encodes an arbitrary date |
| Current build timestamp | ❌ | Changes archive bytes between builds |

### Optimized JARs

| Option | Verdict | Why |
|--------|---------|-----|
| Wait for native ProGuard support | ❌ | Defers reproducibility until [issue #28][1] is resolved |
| ProGuard directory processing followed by Maven JAR | ✅ | Preserves transformations and uses Maven's stable archive timestamps |
| ProGuard JAR output with a timestamp flag | ❌ | ProGuard 7.8.2 exposes no such flag |
| Normalize completed ProGuard archives | ❌ | Changes finished artifacts instead of making archive creation deterministic |

### CAP files

| Option | Verdict | Why |
|--------|---------|-----|
| Upgrade to Java Card Development Kit Tools 26.0 | ❌ | Tested with target 3.0.5; ZIP and manifest timestamps still use wall-clock time |
| Wait for native Oracle support | ❌ | Makes progress dependent on upstream |
| Normalize converter output with Maven plugins | ✅ | Stabilizes ZIP and manifest timestamps while preserving component bytes |

Unlike ProGuard, the Oracle converter offers no directory output suitable for deterministic packaging, so CAPs require
normalization of the completed archive.

## Supporting research

### Artifact overview

- ✅ Verified byte-identical output in manual comparisons
- ❌ Verified differing output in manual comparisons
- ≈ Content comparability or valid signature verification is the goal; no byte-reproducibility claim
- 🔧 Implemented workaround
- 🔍 Investigation

Checks assume identical sources, dependencies, toolchains and timestamp property values. Unchecked outputs are not
advertised as reproducible.

For test, security and HTML reports and JaCoCo execution data / XML, content comparability is the goal, not
byte-identical output. This is not a verified reproducibility claim; test outcomes, coverage and security findings
must be compared with their execution and scan inputs.

Detached GPG signatures are validated against the artifact and expected signing key, not compared byte-for-byte.
Their signature creation timestamps may differ between signing runs.

| Artifact / output | Reproducibility | Solution | Remaining work |
|-------------------|----------------|----------|----------------|
| Standard JVM JAR | ✅ | Maven timestamp support | - |
| Shaded executable JVM JAR (Java, Kotlin, Micronaut) | ✅ | Retains reproducible input timestamps | - |
| Optimized JVM `-proguard.jar` | ✅ | 🔧 ProGuard directory output → Maven JAR | Remove workaround after native support |
| JavaCard shaded JAR | ✅ | Retains reproducible input timestamps | - |
| JavaCard CAP, normal or optimized | ✅ | 🔧 Maven Assembly/Maven Archiver normalization | Remove workaround after native support |
| JavaCard EXP, normal or optimized | ✅ | Converter output is byte-identical in tested builds | - |
| JavaCard JCA, normal or optimized | ❌ | Converter writes wall-clock time and timezone in a comment | 🔍 Investigate native support or comment normalization |
| Container image (Kotlin/Micronaut) | ❌ | Image creation time and added-layer file timestamps differ | Normalization evaluated but deferred due to complexity |
| CycloneDX / SPDX JSON SBOMs | ✅ | Native plugin reproducibility with the stable Maven timestamp | - |
| Test XML / text reports (Surefire / Failsafe) | ≈ | Compare test outcomes; durations and environment data may differ | - |
| Failsafe summary XML | ✅ | Stable test summary with identical test outcomes in checked runs | - |
| License text report | ✅ | Stable dependency/license metadata in checked builds | - |
| JaCoCo coverage CSV | ✅ | Stable measured coverage with identical coverage results in checked runs | - |
| JaCoCo execution data / coverage XML | ≈ | Compare measured coverage; session identifiers and timestamps may differ | - |
| HTML reports | ≈ | Compare test outcomes, coverage, license metadata and security findings; Maven build time and runtime data may differ | - |
| Detached GPG signatures | ≈ | Verify the artifact with the expected signing key; signature creation timestamps may differ | - |

### ProGuard workaround

[ProGuard 7.8.2's OutputWriter](https://github.com/Guardsquare/proguard/blob/v7.8.2/base/src/main/java/proguard/OutputWriter.java)
uses `new Date()` for ZIP timestamps and exposes no timestamp option. Native support is tracked in [issue #28][1].
Directory input also avoids ProGuard recreating a nested JAR in directory output.

| Step | Plugin | Result |
|------|--------|--------|
| Clear intermediate output in `prepare-package` | Maven Clean | Empty `classes-shaded/` and `classes-proguard/`; compiled classes retained |
| Extract the shaded main JAR after Shade in `package` | Maven Dependency | `target/classes-shaded/`; current project artifact, no intermediate install |
| Process classes and resources | ProGuard | `target/classes-proguard/`, including the processed manifest |
| Package optimized output | Maven JAR | Attached `*-proguard.jar` with stable timestamps |

Force extraction despite unpack markers. Exclude backup and patch files (`*~`, `*.bak`, `*.orig`, `*.rej`) while
retaining runtime resources and Maven JAR's default exclusions. Keep JVM ProGuard configuration in the optional
profile's `pluginManagement` so Micronaut can extend it and JavaCard can replace it; retain `skip=true` outside the
profile. JavaCard uses its existing directory pipeline and disables the JVM extraction and packaging executions.
User-facing usage is documented under [size optimization](../../Features.md#size-optimization).
Runtime checks confirmed that the optimized Java, Kotlin and Micronaut JARs remain runnable.

### JavaCard .cap workaround

Manual normal and optimized builds with Java Card SDK 3.0.5u4 and jcdk-maven-plugin 0.1.0 produced matching component
bytes, bundled classes, `APPLET-INF/applet.xml` and entry ordering, but different complete CAP hashes. ZIP timestamps
and `Java-Card-CAP-Creation-Time` use wall-clock time. `CapWriter` initializes its timestamp with
`System.currentTimeMillis()` and formats the manifest value with `Date.toString()`, introducing the default timezone.
Maven's timestamp property does not control these values. The converter help and
[Java Card 3.2 converter options](https://docs.oracle.com/en/java/javacard/3.2/jctug/running-converter.html)
expose no timestamp option.

An isolated test of Tools 26.0 (build 705, 04-May-2026), with `-target 3.0.5` and verification enabled, produced CAP
format 2.1 but remained wall-clock dependent, even with fixed `SOURCE_DATE_EPOCH`. Component contents and ordering
matched; ZIP and manifest timestamps did not. This tested the converter, not Maven-plugin compatibility or a physical
card. Upgrading alone does not solve reproducibility; the Maven toolchain remains unchanged.

| Step | Plugin | Result |
|------|--------|--------|
| Clear intermediate and converter output | Maven Clean | Removes `cap-work/`, `generated-jcdk/`, `classes-proguard/` and previous AID-named converter files; compiled classes retained |
| Convert classes in `process-test-classes` | JCDK | Raw CAP |
| Copy CAP with a ZIP extension | Maven Assembly (`dir`) | `target/cap-work/input.zip` |
| Register current project coordinates as type `cap` in `prepare-package` | Build Helper | Resolvable local input without an intermediate install |
| Extract registered artifact | Maven Dependency | `cap-work/unpacked/`; unknown `cap` type falls back to the `.zip` extension |
| Package contents and override manifest creation time | Maven Assembly (`jar`) / Maven Archiver | `cap-work/input.jar` with stable ZIP and manifest timestamps |
| Replace temporary attachment in `package` | Build Helper | Final AID-named CAP path |
| Copy normalized archive to that path | Maven Assembly (`dir`) | Final CAP contents, before signing and installation |

Assembly uses `destName` for copying and renaming. Maven Archiver merges the fileset manifest first, then overrides
`Java-Card-CAP-Creation-Time` in the named section derived from `main.class`. Do not use `manifestFile`: it gives the
original timestamp precedence. Disable default manifest additions and Maven descriptors to avoid JAR-specific metadata.
Normalization preserves CAP component bytes; Oracle's verifier accepted both normal and optimized normalized CAPs.
The temporary ZIP exists only for extraction; only the final CAP remains attached.

### JavaCard EXP / JCA checks — 2026-11-17

Two clean builds per profile (normal and `size-optimization`) with Java Card SDK 3.0.5u4 and
jcdk-maven-plugin 0.1.0 used identical sources, toolchains and explicit timestamp property values, but separate
directories, different source/resource modification times, build times and JVM timezones (UTC and Pacific/Honolulu).
Both the generated and AID-named EXP files were byte-identical within each profile. JCA files differed only in
the second-line `// on ...` comment, which contains the converter's wall-clock time and default timezone.
The stable Maven timestamp does not control that comment. No JCA normalization is implemented or decided here.

### Kotlin/Micronaut container checks — 2026-11-17

Two uncached builds of the example Dockerfile with Docker Engine 29.8.2 and its default BuildKit docker driver
used a byte-identical executable JAR, separate build contexts and different JAR modification times. Both reused
the same local `eclipse-temurin:25.0.4_7-jre-alpine` base image without pulling updates (image ID
`sha256:e3e307dd691c09d34017dd84320207c60c456c11b29cea9ea94992b0d1afb850`).

Image IDs, creation timestamps and all three added-layer content hashes differed. Inspection of saved layer
archives found identical file contents, permissions, ownership and links, but different file/directory timestamps
from `RUN`, `WORKDIR` and `COPY`. The runtime configuration and inherited base layers matched. The current
`docker build` command does not normalize these timestamps. This isolates image packaging from Maven/JAR
reproducibility; no container normalization is implemented or decided here. The tag-based base reference also
remains mutable across builds, as noted in ADR-0023.

An isolated follow-up with BuildKit 0.34.2 using the `docker-container` driver tested `SOURCE_DATE_EPOCH`
and the OCI export option `rewrite-timestamp=true`. The default Docker driver did not apply the layer rewrite
in the tested Docker export. With the separate builder, rewriting stabilized newly created timestamps, but
retained JAR mtimes older than the selected epoch. A temporary artifact stage that sets the JAR mtime to the
epoch before copying it into the final runtime stage closed that gap. Two uncached builds with the same
digest-pinned base, platform, JAR bytes and epoch, but different original JAR mtimes, produced the identical
OCI image manifest digest `sha256:a041ee7daea54ac8445f29572dee9fc6af78c74447959759385d907d6adfd3b9`.
Provenance was disabled for this image-only comparison. This was an isolated experiment, not a change to the
repository Dockerfile or CI policy.

A subsequent integration prototype also produced identical locally loaded image IDs, but was withdrawn after
review because the separate builder, export options and intermediate stage added too much complexity for the
example project. The existing Dockerfile and CI build remain unchanged; container reproducibility is not claimed.

### CycloneDX / SPDX SBOM checks — 2026-11-17

Two clean builds per profile (`sbom`, and `sbom,size-optimization`) for each Java, Kotlin, Kotlin Micronaut and
JavaCard example produced byte-identical CycloneDX and SPDX JSON files within the matching profile. Builds used
identical sources, Git metadata, dependencies, toolchains and explicit timestamp values, but separate directories,
different source/resource mtimes, build times and JVM timezones (UTC and Pacific/Honolulu). Java tests ran;
the other examples skipped tests, and Micronaut Test Resources was disabled for this packaging comparison.

CycloneDX Maven plugin 2.9.3 reported `cdx:reproducible=enabled`, omitted the variable metadata timestamp and
produced a stable serial number despite `includeBomSerialNumber=true`. SPDX Maven plugin 1.0.4 used the supplied
timestamp for `creationInfo.created` and produced stable document namespaces and identifiers. No additional
configuration or normalization was needed. Comparisons are within identical profiles; enabling optimization
changed the SPDX package checksum, so normal and optimized SBOMs are not required to match each other.

### Test, coverage, license and report checks — 2026-11-17

Paired clean `verify` builds of all four examples enabled tests, `coverage`, `license-check`, `sbom` and
`vulnerability-report`; Java was also checked with `size-optimization`. Inputs and toolchains matched, while
directories, mtimes, build times and timezones differed.

- License text/HTML, coverage CSV and Failsafe summary XML were byte-identical in matching runs.
- Test XML/text varied in durations and environment metadata. JaCoCo XML differed only in session metadata;
  measured coverage matched, while execution-data bytes differed.
- Coverage HTML, report index and dependency/container vulnerability HTML differed only in header time.
  Container scans used the same image; all vulnerability comparisons used a fixed Grype version/database,
  with updates and age checks disabled only for these isolated comparisons—not current security assessments.

Custom HTML headers now share the formatted Maven build time (`build.reports.timestamp`), not the Git archive
timestamp. Matching headers, configurable format/timezone and default unit-report generation were verified.
License templates cannot access this metadata and omit it. No byte-reproducibility normalization is applied;
test outcomes, coverage and findings remain dependent on their execution and scan inputs.

[1]: https://github.com/Guardsquare/proguard/issues/28

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
- 🔧 Implemented workaround
- 🔍 Investigation

Checks assume identical sources, dependencies, toolchains and timestamp property values. Unchecked outputs are not
advertised as reproducible.

| Artifact / output | Reproducibility | Solution | Remaining work |
|-------------------|----------------|----------|----------------|
| Standard JVM JAR | ✅ | Maven timestamp support | - |
| Shaded executable JVM JAR (Java, Kotlin, Micronaut) | ✅ | Retains reproducible input timestamps | - |
| Optimized JVM `-proguard.jar` | ✅ | 🔧 ProGuard directory output → Maven JAR | Remove workaround after native support |
| JavaCard shaded JAR | ✅ | Retains reproducible input timestamps | - |
| JavaCard CAP, normal or optimized | ✅ | 🔧 Maven Assembly/Maven Archiver normalization | Remove workaround after native support |
| JavaCard EXP, normal or optimized | ✅ | Converter output is byte-identical in tested builds | - |
| JavaCard JCA, normal or optimized | Not reproducible | Converter writes wall-clock time and timezone in a comment | 🔍 Evaluate native support or normalization separately |
| Container image (Kotlin/Micronaut) | Not checked | - | 🔍 Investigate image timestamps and builder support |
| CycloneDX / SPDX SBOMs | Not checked | - | 🔍 Investigate timestamps, identifiers and generator options |
| Test, coverage, license and other reports | Not checked | - | 🔍 Assess measurements, paths and metadata |
| Detached GPG signatures | Not checked | - | 🔍 Assess signing timestamps and cryptographic metadata |

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

[1]: https://github.com/Guardsquare/proguard/issues/28

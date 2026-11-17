---
status: proposed
date: 2026-11-17
supersedes: []
superseded-by: []
---

# 0029: Build reproducibility

> Proposed: Standard and optimized JAR packaging and CAP normalization are implemented; other outputs remain under evaluation.

## Context

Resource modification times and environment-dependent metadata can change archive bytes without a source change.
The parent collection already uses Git metadata and should derive deterministic JVM packaging timestamps from
the source commit. Optional reports, signing and specialized packaging have different reproducibility concerns.

## Decision

Set Maven's standard `project.build.outputTimestamp` property to `${git.commit.time}` in the Java parent
for consumer projects. Activate git-commit-id by default in `initialize` for non-POM consumers and format commit dates as
ISO-8601 in UTC. Consumers may override the timestamp. Projects in non-Git repositories and source archives
without Git are explicitly supported: they must supply a stable release timestamp through
`project.build.outputTimestamp` (in the POM or via `-Dproject.build.outputTimestamp`, as ISO-8601 or epoch seconds).
An Enforcer check before packaging rejects a missing or unresolved timestamp to prevent silently falling back
to current file modification times. Git is not a build requirement; a stable timestamp is.
Currently, JVM consumers' main JARs and optimized `-proguard.jar` artifacts are in scope, together with the contents
of JavaCard's ProGuard output directory before CAP conversion and normalized CAP files. The parent POMs and the standalone `maven-build-config` module
are not required to be reproducible. The timestamp check does not apply to `packaging=pom` projects.
Use the `reproducible-build` profile, automatically activated when packaging is not `pom`; consumers need no `-P`.
ProGuard remains optional through `size-optimization`. Keep JVM-specific ProGuard configuration in that profile's
`pluginManagement` so Micronaut can extend it and JavaCard can replace it. Outside the profile, retain `skip=true`
as the safe default, together with plugin/tool versions and dependencies.

For JVM consumers using `size-optimization`, extract the shaded input JAR into `classes-shaded`, run ProGuard from
that directory into `classes-proguard`, then let Maven JAR create the attached `proguard` artifact in `package`.
Use ProGuard's processed manifest and runtime resource/class output, retaining the existing main artifact and
classifier. Clear the intermediate directories before extraction to avoid stale output on repeated builds.
Use a targeted Maven Clean execution in `prepare-package` and Maven Dependency `unpack` after Shade in `package`.
Exclude the default clean directories so compiled classes and other outputs remain intact. Resolve the current
project's artifact from the reactor, without an intermediate install, and force extraction despite unpack markers.
Exclude backup and patch files (`*~`, `*.bak`, `*.orig`, `*.rej`) through a shared ProGuard input filter for all
consumers. Retain Maven JAR's standard archive exclusions, including `package.html`; these files are not runtime assets.

This changes archive creation, not the bytecode or keep policies in ADR-0017. ProGuard 7.8.2 constructs ZIP entry
timestamps from `new Date()` in its `OutputWriter` and exposes no timestamp option. Maven JAR supports the stable
timestamp already configured above. Directory input avoids ProGuard recreating a nested JAR in directory output.
We do not normalize or repack ProGuard output archives afterward. JavaCard retains its existing directory pipeline;
the JVM extraction and archive creation executions are disabled there.

This extraction → ProGuard directory output → Maven JAR pipeline is a crude, temporary workaround, not the
preferred architecture. Keep it only until ProGuard officially supports reproducible output archives, tracked in
[ProGuard issue #28](https://github.com/Guardsquare/proguard/issues/28).

Check JVM consumers' main and optimized JARs manually using two clean builds with matching profiles and compare
their SHA-256 hashes with `sha256sum`. For JavaCard, compare relative file paths and file-content hashes in
`target/classes-proguard` after `process-classes`, before CAP conversion; filesystem timestamps are not part of that
comparison. JavaCard's converter reads `target/classes` normally and `target/classes-proguard` with `size-optimization`.
Do not add extra builds to normal CI; document user-facing requirements and limitations in `Features.md`.
Use separate directories and distinct resource mtimes, but identical Git metadata and toolchains.
Keep the normal full CI verification build and its outputs independent of these checks.

### CAP normalization

Use a temporary CAP normalization workaround without Exec or AntRun. It stabilizes ZIP and manifest timestamps
while preserving component bytes. The final CAP is installed and signed, never the intermediate ZIP.
This is a CAP-only exception to avoiding completed-archive post-processing. Use the identical timestamp property
value for rebuilds; equivalent ISO/epoch representations need not produce identical manifest bytes.

### Follow-up when upstream support becomes available

- **ProGuard:** Once upstream supports reproducible builds, adopt that support and remove our packaging workaround.
- **Oracle Java Card tools:** Once upstream supports reproducible CAPs, adopt that support and remove any CAP
  normalization workaround introduced in the meantime.

## Artifact overview

This overview describes the current consumer build, not theoretical guarantees. ✅ means verified by manual
same-source, same-toolchain comparisons; identical dependencies and a stable commit/release timestamp remain
prerequisites. Unchecked outputs must not be advertised as reproducible.
In the solution column, ✅ means native support without a workaround, 🔧 an implemented workaround, and - no
verified solution yet. 🔍 marks remaining investigation.

| Artifact / output | Current reproducibility status | Solution | Remaining work |
|-------------------|--------------------------------|------------------------|----------------|
| Standard JVM JAR | ✅ | ✅ Native Maven timestamp support | - |
| Shaded executable JVM JAR (Java, Kotlin, Micronaut) | ✅ | ✅ Retains reproducible input timestamps | - |
| Optimized JVM `-proguard.jar` | ✅ | 🔧 Cleanup → shaded-JAR extraction → ProGuard directory output → Maven JAR packaging | 🔍 Remove workaround once ProGuard supports reproducible archives |
| JavaCard shaded JAR | Timestamp configuration inherited; not separately verified as a final artifact | - | 🔍 Compare final JAR hashes |
| JavaCard CAP, normal or optimized | ✅ | 🔧 Unpack, replace manifest timestamp and repackage with stable ZIP timestamps | 🔍 Remove normalization once Oracle provides native support |
| JavaCard EXP / JCA companion outputs | Not checked | - | 🔍 Compare independently; determine whether metadata needs configuration or normalization |
| Container image (Kotlin/Micronaut example) | Not checked or claimed | - | 🔍 Investigate image timestamps, base-image identity and image-builder support |
| CycloneDX / SPDX SBOMs | Not checked or claimed | - | 🔍 Investigate generated timestamps, identifiers and generator options |
| Test, coverage, license and other reports | Not checked or claimed | - | 🔍 Assess runtime measurements, paths, timestamps and tool-specific metadata separately |
| Detached GPG signatures | Not checked or claimed | - | 🔍 Assess signing timestamps and cryptographic metadata independently of unsigned artifacts |

CAP normalization is a CAP-only exception to avoiding post-processing completed archives;
the ProGuard pipeline is unchanged.

## CAP investigation

Manual checks with Java Card SDK 3.0.5u4 and jcdk-maven-plugin 0.1.0 compared two clean consumer builds in
separate directories with different source mtimes, both normally and with `size-optimization`. In each profile,
CAP component bytes, bundled classes, `APPLET-INF/applet.xml` and archive entry ordering matched. Full CAP hashes
did not match: ZIP entry timestamps and the manifest's `Java-Card-CAP-Creation-Time` use the current build time.

Inspection of the SDK's `com.sun.javacard.jcasm.cap.CapWriter` shows that its constructor initializes `timeStamp`
with `System.currentTimeMillis()`. The manifest formats that value with `Date.toString()`, also introducing the
default timezone. The manifest entry is created by `JarOutputStream` without a supplied stable timestamp.
Maven's `project.build.outputTimestamp` therefore does not control CAP creation in the current pipeline.

The installed converter's help exposes no timestamp option. The Java Card 3.2 command-line documentation likewise
lists no such option.

A subsequent isolated test used Java Card Development Kit Tools 26.0 (build 705, 04-May-2026), invoking the converter
directly with `-target 3.0.5` on the matching normal and ProGuard-optimized class outputs above. Conversion succeeded
with verification enabled and produced CAP format 2.1. This checks the converter, not Maven-plugin compatibility
or execution on a physical card. Runs in separate directories with different class mtimes and separated build
times still produced different CAP hashes in both profiles. Component contents and entry ordering matched;
the manifest creation time and ZIP timestamps remained wall-clock dependent even with a fixed `SOURCE_DATE_EPOCH`.
Tools 26.0's `CapWriter` still initializes its timestamp from `System.currentTimeMillis()` and formats the manifest
creation time with `Date.toString()`. Its help exposes no timestamp option. A tools upgrade alone therefore does
not solve reproducibility; the existing Maven toolchain remains unchanged.

Native CAP reproducibility remains blocked for both tested tool versions. The build therefore normalizes the
converter output; system clock manipulation is not used.

## Options considered

### Reproducible standard JARs

| Option | Verdict | Why |
|--------|---------|-----|
| Use the Git commit timestamp by default, allow an explicit stable timestamp | ✅ | Reflects the source revision and reuses the existing plugin; a stable commit or release timestamp can be supplied via `project.build.outputTimestamp` in the POM or command line, including consumers without Git |
| Fixed overridable timestamp | ❌ | Technically deterministic, but encodes an arbitrary date |
| Current build timestamp | ❌ | Does not produce stable archive bytes |

### Reproducible ProGuard JARs

| Option | Verdict | Why |
|--------|---------|-----|
| Wait for ProGuard support | ❌ | No additional build steps, but reproducibility would depend on upstream issue #28 being resolved; see the workaround rationale above |
| Implement a ProGuard packaging workaround | ✅ | Chosen and implemented: ProGuard directory output and Maven JAR packaging preserve transformations while using Maven's configurable archive timestamps |
| ProGuard JAR output with a timestamp flag | ❌ | ProGuard 7.8.2 exposes no such flag |
| Normalize or repack completed ProGuard `*-proguard.jar` archives | ❌ | Changes finished artifacts afterward instead of making archive creation deterministic |

### Reproducible CAP files


| Option | Verdict | Why |
|--------|---------|-----|
| Upgrade to Java Card Development Kit Tools 26.0 | ❌ | Tested with target 3.0.5; ZIP timestamps and manifest creation time remain wall-clock dependent |
| Leave CAPs unreproducible until Oracle provides native support | ❌ | Avoids extra maintenance, but makes progress dependent on Oracle; we do not want to wait for upstream support |
| Implement CAP timestamp normalization (temporary workaround) | ✅ | Post-process the converter's completed CAP archive to normalize ZIP timestamps and manifest creation time using the stable timestamp property; preserve component bytes and compare SHA-256 hashes of the complete CAP files. This compensates for missing converter support rather than providing native reproducibility and adds maintenance; do not use Exec or AntRun |

## Consequences

Stable archive timestamps are enabled by default. The manual check fails on differing SHA-256 hashes, but CI
does not automatically detect reproducibility regressions. This avoids two additional builds per JVM consumer.
This is a same-toolchain packaging check, not proof of reproducibility across JDKs or dependency changes.
Images, SBOMs, reports and detached signatures remain outside the checked scope.

### ProGuard packaging workaround (implemented)

ProGuard processes extracted shaded-JAR contents rather than creating the optimized archive itself. Maven JAR
then packages the processed classes, resources and manifest with the stable build timestamp.

| Step | Plugin | Result |
|------|--------|--------|
| Clear previous intermediate output | Maven Clean | Empty `classes-shaded/` and `classes-proguard/` |
| Extract the shaded main JAR | Maven Dependency | `target/classes-shaded/` |
| Process classes and resources | ProGuard | `target/classes-proguard/` |
| Package the optimized output | Maven JAR | Attached `*-proguard.jar` with stable archive timestamps |

This adds extraction, intermediate directories and extra I/O, but avoids modifying a finished ProGuard archive.
The shaded main artifact and the existing optimization policies remain unchanged.

### CAP normalization workaround (implemented)

The converter still creates a CAP with wall-clock timestamps. The build extracts it, replaces only
`Java-Card-CAP-Creation-Time` in the manifest, and packages the contents again with stable ZIP timestamps.

| Step | Plugin | Result |
|------|--------|--------|
| Clear previous intermediate and converter output | Maven Clean | Removes `cap-work/`, `generated-jcdk/`, `classes-proguard/` and previous AID-named converter files without removing compiled classes |
| Convert classes to CAP | JCDK | Raw CAP output in `process-test-classes` |
| Copy the converter's CAP as ZIP | Maven Assembly (`dir`) | `target/cap-work/input.zip`, so Maven Dependency recognizes the archive format |
| Register the file under the current project's coordinates with type `cap` | Build Helper | Maven can resolve the local file without an intermediate install |
| Extract the registered artifact | Maven Dependency | `target/cap-work/unpacked/`; the unknown `cap` type falls back to the `.zip` file extension |
| Package the contents and override the manifest creation time | Maven Assembly (`jar`) / Maven Archiver | `target/cap-work/input.jar` with stable ZIP and manifest timestamps; other attributes retained |
| Replace the temporary registration with the final CAP path | Build Helper | The project's `cap` artifact points to `target/<applet-AID-without-colons>.cap` |
| Copy the normalized archive to the final CAP path | Maven Assembly (`dir`) | Replaces the raw AID-named CAP in `package`, before signing and installation |

The initial registration points to `cap-work/input.zip` only for extraction. After repackaging, Build Helper
replaces that registration under the same coordinates with the final AID-named CAP path, and Maven Assembly replaces
that file's contents. Only the final CAP remains attached
for signing, installation and publication; the ZIP is an intermediate file. No Exec, AntRun, TrueZIP or custom
Java code is used.
Assembly's `dir` format copies and renames files using `destName`. Its `jar` format uses Maven Archiver to merge
the converter's fileset manifest first and then override `Java-Card-CAP-Creation-Time` in the package's named section.
The section name is derived from `main.class`. Do not use `manifestFile`: it gives the original timestamp precedence.
Disable default manifest additions and Maven descriptors so the CAP gains no JAR-specific metadata.
Maven reports a warning when the final attachment replaces the temporary one; installation reads the final `.cap`,
not `input.zip`. This expected warning is documented in `Troubleshooting.md`.

This adds file copies, extraction and repackaging, but no Copy/Rename or Replacer plugin dependencies. Unlike the
ProGuard workaround, it modifies a completed archive. Component bytes remain unchanged. Normal and optimized
consumer CAPs produced matching hashes and passed Oracle's verifier. Repeated builds clear stale converter and
intermediate output; source changes without `clean` regenerate the CAP. Detached signatures were verified against
both the final build output and the installed CAP. Only the existing Build Helper and Apache Maven plugins are
used for normalization; the older Copy/Rename and Replacer plugins and their transitive dependencies are removed.

## Verification to date

- The Assembly/Maven Archiver replacement for Copy/Rename and Replacer passed normal and optimized hash,
  component-content, manifest-attribute, verifier, repeated-build, installation and signing checks. A consumer with
  a different applet package confirmed correct manifest-section derivation and repeatable epoch-timestamp builds.
- Normal and optimized JavaCard consumer `clean verify` builds in separate directories with different source
  mtimes and timezones produced matching complete CAP SHA-256 hashes using the same timestamp property value.
  All non-manifest entry contents matched the raw converter output; Oracle's verifier accepted the normalized CAPs.
- Repeated `package` removed stale extracted files and retained matching CAP hashes. Changing applet bytecode
  without `clean` regenerated the CAP. Signed `clean install` builds installed the final CAP; its detached signature
  verified against both the target and installed files using a temporary test key.
- Automatic Git timestamps and explicit epoch overrides each produced matching CAP hashes on repeated normal and
  optimized consumer builds. Fresh artifact coordinates confirmed resolution without an intermediate install;
  installation included the final CAP and no additional ZIP artifact.

- Two isolated builds with different source mtimes produced matching optimized JAR hashes for Java, Kotlin and
  Micronaut, and matching ProGuard output file paths/content hashes for JavaCard.
- Java and Kotlin tests and optimized-JAR launches passed. Micronaut normal and optimized `clean verify` builds
  passed all tests. Both packaged JARs passed health, Git-version, MongoDB-migration and asynchronous order/webhook
  checks with MongoDB, RabbitMQ and WireMock. The optimized-JAR launch exposed missing Javassist proxy support;
  keep rules now preserve it for Mongock's dynamically generated proxies. A repeated optimized build retained
  the same JAR hash after this correction.
- Non-Git Java builds with ISO-8601 and equivalent epoch overrides produced matching optimized JAR hashes.
- Fresh, previously unpublished artifact coordinates confirmed that unpacking reads the current shaded JAR without
  an intermediate install. Repeated `package` removed stale intermediate files without removing compiled classes.
- Backup files were excluded at both root and nested paths, while test runtime resources remained present.
- Effective consumer POMs confirmed profile activation, Micronaut configuration extensions and JavaCard overrides.
  JavaCard disables the JVM cleanup, extraction and optimized-JAR executions. Main and classified JVM artifacts
  remain attached and installable; the standard build does not run the optimization steps.

## References

- [ProGuard 7.8.2 OutputWriter](https://github.com/Guardsquare/proguard/blob/v7.8.2/base/src/main/java/proguard/OutputWriter.java).
- [ProGuard #414: Reproducible output jar](https://github.com/Guardsquare/proguard/issues/414) (closed as duplicate of #28).
- [Size optimization usage](../../Features.md#size-optimization).
- [Java Card 3.2 converter options](https://docs.oracle.com/en/java/javacard/3.2/jctug/running-converter.html).

---
status: proposed
date: 2026-11-17
supersedes: []
superseded-by: []
---

# 0029: Build reproducibility

> Proposed: Standard and optimized JAR packaging is implemented; additional build outputs remain under evaluation.

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
of JavaCard's ProGuard output directory before CAP conversion. The parent POMs and the standalone `maven-build-config` module
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
[ProGuard issue #28](https://github.com/Guardsquare/proguard/issues/28). Once that support is available, verify stable
timestamps and entry ordering, then restore direct shaded-JAR input and
ProGuard JAR output and remove the extra cleanup, extraction and Maven JAR executions.

Check JVM consumers' main and optimized JARs manually using two clean builds with matching profiles and compare
their SHA-256 hashes with `sha256sum`. For JavaCard, compare relative file paths and file-content hashes in
`target/classes-proguard` after `process-classes`, before CAP conversion; filesystem timestamps are not part of that
comparison. JavaCard's converter reads `target/classes` normally and `target/classes-proguard` with `size-optimization`.
Do not add extra builds to normal CI; document user-facing requirements and limitations in `Features.md`.
Use separate directories and distinct resource mtimes, but identical Git metadata and toolchains.
Keep the normal full CI verification build and its outputs independent of these checks.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Automatically derive from Git | ✅ | Reflects the source revision and reuses the existing plugin |
| Fixed overridable timestamp | ❌ | Technically deterministic, but encodes an arbitrary date |
| Current build timestamp | ❌ | Does not produce stable archive bytes |
| ProGuard directory output, Maven JAR packaging | ✅ | Preserves ProGuard transformations while using Maven's configurable archive timestamps |
| ProGuard JAR output with a timestamp flag | ❌ | ProGuard 7.8.2 exposes no such flag |
| Normalize or repack completed ProGuard archives | ❌ | Changes finished artifacts afterward instead of making archive creation deterministic |

## Consequences

Stable archive timestamps are enabled by default. The manual check fails on differing SHA-256 hashes, but CI
does not automatically detect reproducibility regressions. This avoids two additional builds per JVM consumer.
This is a same-toolchain packaging check, not proof of reproducibility across JDKs or dependency changes.
JVM optimization now needs input extraction and two intermediate directories. The extra I/O is the cost of avoiding
ProGuard's wall-clock archive timestamps without patching the tool or post-processing finished artifacts.
JavaCard CAPs, images, SBOMs, reports and detached signatures remain outside the checked scope.

## Verification to date

- Two isolated builds with different source mtimes produced matching optimized JAR hashes for Java, Kotlin and
  Micronaut, and matching ProGuard output file paths/content hashes for JavaCard.
- Java and Kotlin tests and optimized-JAR launches passed. Micronaut's manifest, service files and generated metadata
  were checked, but its full application startup and integration tests were not run for this packaging change.
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

---
status: proposed
date: 2026-11-17
supersedes: []
superseded-by: []
---

# 0029: Build reproducibility

> Proposed: JAR timestamp support is implemented; the scope will be expanded to other build outputs before acceptance.

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
Currently, only JVM consumers' main JARs from standard packaging are in scope. The parent POMs and the standalone `maven-build-config` module
are not required to be reproducible. The timestamp check does not apply to `packaging=pom` projects.
Use the `reproducible-build` profile, automatically activated when packaging is not `pom`; consumers need no `-P`.

Check JVM consumers' main JARs manually using two clean standard packaging builds and compare their SHA-256
hashes with `sha256sum`. Do not add extra builds to normal CI; document the manual procedure in `Features.md`.
Use separate directories and distinct resource mtimes, but identical Git metadata and toolchains.
Keep the normal full CI verification build and its outputs independent of these checks.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Automatically derive from Git | ✅ | Reflects the source revision and reuses the existing plugin |
| Fixed overridable timestamp | ❌ | Technically deterministic, but encodes an arbitrary date |
| Current build timestamp | ❌ | Does not produce stable archive bytes |

## Consequences

Stable archive timestamps are enabled by default. The manual check fails on differing SHA-256 hashes, but CI
does not automatically detect reproducibility regressions. This avoids two additional builds per JVM consumer.
This is a same-toolchain packaging check, not proof of reproducibility across JDKs or dependency changes.
ProGuard, JavaCard CAPs, images, SBOMs, reports and detached signatures remain outside the checked scope.

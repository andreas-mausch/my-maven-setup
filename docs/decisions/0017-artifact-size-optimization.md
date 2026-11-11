---
status: accepted
date: 2026-05-17
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0017: Artifact size optimization

> Recorded retroactively on 2026-11-11. The date records the JavaCard profile; Java/Kotlin
> support and framework-specific restrictions are later extensions.

## Context

JavaCard devices have limited storage capacity, making small applet binaries particularly
desirable. Applications bundling many dependencies can also benefit from a smaller footprint.
Removing unused code can help, but dynamic lookups and generated framework metadata make
aggressive bytecode transformations risky.

Obfuscation is not a goal for the author. Tools may offer it alongside shrinking and
optimization, but making code harder to understand is not a reason for this feature.

## Decision

Offer ProGuard through the `size-optimization` profile. For ordinary Java/Kotlin applications,
shrink and optimize the shaded JAR, attaching the result with the `proguard` classifier while
retaining the shaded main artifact. For Micronaut, shrink only: disable optimization and
obfuscation and preserve required metadata through keep rules. For JavaCard, remove unused
bytecode before packaging the CAP file. Preserve the configured application entry point.

The goal is reducing artifact size, not obfuscating the application. The current ordinary
Java/Kotlin configuration also performs obfuscation, but that is existing tool behaviour,
not a project requirement or a reason for selecting ProGuard.

## Consequences

- **Positive:** Consumers can reduce footprint without replacing the normal application artifact.
- **Negative:** Keep rules and library inputs need maintenance; transformations can break
  reflection, serialization, dependency injection or native integrations.
- **Risks / neutral:** A smaller artifact is not proof of equivalent runtime behaviour. Verify
  executable outputs, and revisit Micronaut's restrictions only with end-to-end evidence that
  the generated metadata and dynamic integrations still work.

## Options considered

ProGuard is implemented; no shrinker comparison is recorded.

## References

- Git `4940ae7` (2026-05-17): optional JavaCard optimization.
- Git `c559604` (2026-09-12): Java-parent ProGuard support.
- Git `2b00820`, `21c2b26` (2026-09-13): optimize shaded outputs in the correct lifecycle order.
- [Optimization behaviour and restrictions](../../Features.md#size-optimization).

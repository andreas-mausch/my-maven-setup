---
status: accepted
date: 2026-09-15
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0018: Kotlin annotation processing

> Recorded retroactively on 2026-11-11 from the kapt-to-KSP migration and its explicit rationale.

## Context

Micronaut's Kotlin build needs processors for dependency injection, data access and serialization.
The processing integration should be actively maintained and fit Maven's generated classes and
source layout without creating duplicate generated-source roots.

## Decision

Use KSP through `ksp-maven-plugin` instead of kapt for the Kotlin Micronaut parent. Write the
generated bean definitions to Maven's main and test output directories. Retain the shared
Maven packaging rather than adopting another build tool for processor integration.

## Consequences

- **Positive:** Uses the actively developed processing approach and avoids the duplicate
  generated-source roots documented for the prior kapt setup.
- **Negative:** Integrations must supply KSP-compatible processors; JSR 269-only processors
  cannot be executed by the KSP plugin.
- **Risks / neutral:** KSP does not remove Maven's plugin dependency version limitations.
  Framework compatibility and Maven integration still need verification on upgrades.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| KSP | ✅ | Actively developed and avoids the previous duplicate generated-source roots |
| Retain kapt | ❌ | The documented rationale identifies maintenance mode and source-root issues |

## References

- Git `ebd742b`, `c65e14d` (2026-09-15): migration and rationale.
- [Micronaut setup](../../README-kotlin-micronaut.md).
- [ADR-0005](0005-micronaut-processor-version-management.md): version management.
- [ADR-0006](0006-database-migration-integration.md): JSR 269 integration limitation.

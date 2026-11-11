---
status: accepted
date: 2026-09-23
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0024: Compiler warning policy

> Recorded retroactively on 2026-11-11 from the warning policy, tests and exception guidance.

## Context

Compiler warnings should receive attention rather than disappear in successful build logs.
Consumers need a consistent default for Java and Kotlin, while some warnings may require
narrow suppression or a documented temporary exception.

## Decision

Fail Java and Kotlin builds on compiler warnings by default. Prefer fixing the warning or
suppressing it narrowly. Allow a consumer to set `fail.on.warning` to `false` only when that
is not practical. Verify both default rejection and the explicit escape hatch in CI fixtures.

## Consequences

- **Positive:** Compiler diagnostics become actionable build failures under the default policy.
- **Negative:** Toolchain or dependency upgrades can introduce warnings that interrupt builds.
- **Risks / neutral:** The broad escape hatch disables the gate for that consumer and requires
  care. Compiler warnings are distinct from JVM or plugin runtime warnings; this policy does
  not make every warning-looking log line fatal or replace static analysis.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Warnings fail by default with an explicit override | ✅ | Matches the implemented policy and documented exception guidance |
| Leave warnings informational by default | Replaced | Was the previous behaviour before the warning-as-error change |

## References

- Git `2e29b94`, `fd569cb` (2026-09-23): warning policy and positive/negative verification.
- [Compiler warnings](../../Features.md#compiler-warnings).
- [Negative consumer tests](../../.github/workflows/negative-tests.yaml).

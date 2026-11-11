---
status: accepted
date: 2026-09-23
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0006: Database migration integration

> Recorded retroactively on 2026-11-11. `dfca19d` (2026-09-23) is the first explicit
> record of retaining Mongock rather than adopting Flamingock. Earlier Mongock use does
> not establish when Flamingock was considered and rejected for this setup.

## Context

The Kotlin/Micronaut example uses Mongock for database migrations and KSP for annotation
processing. With Flamingock available as Mongock's successor, we need to decide whether to
migrate. We want a maintainable migration setup that works with Maven and Kotlin without
disproportionate build complexity. Native Image support is an additional reason to evaluate
the successor.

## Decision

Keep KSP and Mongock. Do not add a second processing pipeline or change the example's language
or build tool solely to integrate Flamingock. Treat retaining Mongock as a temporary integration
compromise rather than a preference over its successor.

Replace it with Flamingock once Flamingock offers a KSP processor compatible with
`ksp-maven-plugin`, or another clean Maven/Kotlin integration that does not require kapt,
and an isolated consumer build verifies compilation, tests and execution of the Kotlin database
migrations. Record that replacement in a superseding ADR.

## Consequences

- **Positive:** Keeps the example's Maven/Kotlin processing pipeline simple.
- **Negative:** Retains the older migration tool and blocks a supported native deployment artifact.
- **Risks / neutral:** A working Flamingock integration alone does not establish Native Image
  support; the native deployment artifact needs separate end-to-end verification under ADR-0007.

## Options considered

At the time of this decision, Flamingock's Maven integration uses a JSR 269 processor executed
by `maven-compiler-plugin`. The KSP Maven plugin runs KSP processors, not JSR 269 processors,
and javac cannot process the example's Kotlin migration classes. A switch therefore needs
one of the workarounds below rather than a direct dependency replacement.

| Option | Verdict | Why |
|--------|---------|-----|
| KSP and Mongock | ✅ | Fits the existing processing pipeline |
| Direct switch to Flamingock with KSP | ❌ | Its JSR 269 processor cannot run through the KSP Maven plugin |
| Add kapt solely for Flamingock | ❌ | Disproportionate processing complexity |
| Rewrite migrations in Java | ❌ | Disproportionate workaround for the Kotlin example |
| Switch to Gradle | ❌ | Conflicts with the project's build-tool choice |

## References

- Git `dfca19d` (2026-09-23): explicit rationale and adoption conditions.
- [KSP Maven plugin](https://github.com/kpavlov/ksp-maven-plugin).
- [ADR-0001](0001-build-tool.md): build tool.
- [ADR-0007](0007-micronaut-native-image-support.md): Native Image support.

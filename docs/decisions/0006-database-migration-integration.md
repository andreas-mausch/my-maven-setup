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
> The migration mechanism was introduced earlier, in `ba3bf56` (2026-09-17).

## Context

Application versions need reproducible database changes, including index creation. Changes
should not depend on someone remembering to run manual commands, and concurrent application
instances need coordination when applying them.

We want a maintainable migration setup that works with Maven, Kotlin and KSP without
disproportionate build complexity. The example already uses Mongock; with Flamingock available
as its successor, we also need to decide whether to migrate. Native Image support is an
additional reason to evaluate the successor.

## Decision

Use Mongock to apply ordered, versioned migrations before application startup completes.
Track completed migrations and use its distributed locking to coordinate instances.
Keep migration code with the application and log execution. Disable transactions for the
configured example environment.

Keep the KSP processing pipeline. Do not add a second processing pipeline or change the example's
language or build tool solely to integrate Flamingock. Treat retaining Mongock as a temporary
integration compromise rather than a preference over its successor.

Replace it with Flamingock once Flamingock offers a KSP processor compatible with
`ksp-maven-plugin`, or another clean Maven/Kotlin integration that does not require kapt,
and an isolated consumer build verifies compilation, tests and execution of the Kotlin database
migrations. Record that replacement in a superseding ADR.

## Consequences

- **Positive:** Database changes are explicit, reproducible and associated with application
  versions. Completion records avoid reapplying successful migrations, and Mongock fits the
  existing Maven/Kotlin processing pipeline.
- **Negative:** Startup depends on migration success and database availability. Costly or
  destructive migrations require operational care. Keeping the older tool also blocks a
  supported native deployment artifact.
- **Risks / neutral:** Locking and completion tracking do not prove arbitrary side effects
  happen exactly once after failures. Nontransactional migrations must handle partial execution
  and safe retries; rollback declarations do not guarantee data recovery. A working Flamingock
  integration alone does not establish Native Image support, which needs separate end-to-end
  verification under ADR-0007.

## Options considered

At the time of this decision, Flamingock's Maven integration uses a JSR 269 processor executed
by `maven-compiler-plugin`. The KSP Maven plugin runs KSP processors, not JSR 269 processors,
and javac cannot process the example's Kotlin migration classes. A switch therefore needs
one of the workarounds below rather than a direct dependency replacement.

| Option | Verdict | Why |
|--------|---------|-----|
| Mongock with KSP | ✅ | Fits the existing Maven/Kotlin processing pipeline |
| Flamingock with KSP | ❌ | Its JSR 269 processor cannot run through the KSP Maven plugin |
| Flamingock with kapt | ❌ | Adding kapt solely for Flamingock creates disproportionate processing complexity |
| Flamingock with Java migrations (rewrite) | ❌ | Allows JSR 269 processing through javac, but requires a disproportionate rewrite of the Kotlin example |
| Flamingock with Gradle | ❌ | Changing the build tool conflicts with the project's Maven choice |

## References

- Git `ba3bf56`, `5789801`, `f83decc` (2026-09-17): migrations, transaction restriction and logging.
- Git `3ef578b` (2026-09-22): reproducibility rationale.
- Git `dfca19d` (2026-09-23): explicit rationale and adoption conditions.
- [Versioned migrations](../../Features.md#versioned-database-migrations).
- [KSP Maven plugin](https://github.com/kpavlov/ksp-maven-plugin).
- [ADR-0001](0001-build-tool.md): build tool.
- [ADR-0007](0007-micronaut-native-image-support.md): Native Image support.

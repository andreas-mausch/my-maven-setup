---
status: accepted
date: 2026-09-23
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0007: Micronaut Native Image support

> Recorded retroactively on 2026-11-11. The explicit decision not to support a native
> Micronaut artifact was documented in `dfca19d` (2026-09-23), together with ADR-0006's rationale.

## Context

We want to offer a GraalVM Native Image as a Micronaut deployment artifact. It must run the
application's database migrations as well as its HTTP functionality, and we want to verify
that integration end to end before claiming support.

The current migration tool, Mongock, does not support Native Image. Its successor Flamingock
does, but ADR-0006 explains why we cannot currently integrate it cleanly into this Maven/Kotlin
build. These technical restrictions block the desired native artifact.

## Decision

Temporarily defer a supported native Micronaut executable because the current migration
integration cannot support it. This is a technical limitation, not a preference against
Native Image; a native deployment artifact remains a desired outcome.

Add native artifact support once a Native Image-compatible migration integration works in
our Maven/Kotlin setup and an isolated consumer build verifies native compilation, application
startup, HTTP functionality and database migration execution. A successful Flamingock migration
alone is not sufficient. Record native support in a superseding ADR.

## Consequences

- **Positive:** Avoids claiming support for an artifact whose database migrations cannot work
  with the selected migration tool.
- **Negative:** Native deployment benefits are unavailable in the supported example.
- **Risks / neutral:** Until the restrictions are resolved, native deployment remains outside
  the supported and verified capabilities of the example.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Defer a supported native deployment artifact | ✅ | Mongock does not support Native Image, and ADR-0006 explains why a Flamingock migration is not currently practical |
| Treat a native executable as supported now | ❌ | The selected migration integration cannot support it |

## References

- Git `dfca19d` (2026-09-23): explicit native-artifact deferral.
- [ADR-0006](0006-database-migration-integration.md): database migration integration.

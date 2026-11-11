---
status: accepted
date: 2026-09-11
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0004: Build isolation

> Recorded retroactively on 2026-11-11. Separate parent POMs existed by `e06e320`
> (2025-10-08), but that alone does not establish the full consumer-isolation policy.
> Consumer isolation was implemented in `9d6a7a8`, and the root reactor removed in
> `8d33c18` (both 2026-09-11). The consolidated rationale followed in `cba7b47` that day.

## Context

We need confidence that published parent POMs and shared resources work in external projects.
Tests inside the source checkout can miss dependencies on unpublished artifacts or local
parent files. The build and test setup should reveal those problems before a release, while
still allowing development of related parent sources from the same commit.

## Decision

Build and publish all five artifacts independently, without a root aggregator POM. Resolve
dependencies from Maven repositories. Examples use `<relativePath />` to disable filesystem
parent lookup. CI copies examples outside this repository and builds them against installed
artifacts as isolated consumers.

Specialized parents retain local references to their direct parent so building those parent
sources from this repository uses the same commit. This does not change the isolated examples.

## Consequences

- **Positive:** Consumer tests exercise repository resolution and packaged shared resources,
  rather than accidentally depending on the parent source checkout.
- **Negative:** Local development requires installing dependencies in order before testing
  consumers; there is no single root reactor build.
- **Risks / neutral:** Kotlin and JavaCard are sibling builds. Micronaut follows Kotlin.
  An example's released parent version is not automatically the current snapshot.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Independent artifact builds and isolated consumer copies | ✅ | Exercises repository resolution and packaged resources as external consumers use them |
| Rely only on a root reactor or in-checkout examples | ❌ | Can hide dependencies on unpublished artifacts or local parent files |

## References

- Git `e06e320` (2025-10-08): separate Java and JavaCard parent POMs.
- Git `9d6a7a8`, `8d33c18` (2026-09-11): isolate consumer tests and remove the root reactor.
- Git `cba7b47` (2026-09-11): explicit independent-build and consumer-isolation policy.
- Git `fe3fe98` (2026-09-11) and `c41333d` (2026-09-15): Kotlin and Micronaut build ordering.
- [Local installation instructions](../../README.md#development).
- [ADR-0003](0003-artifact-versioning.md): artifact versioning.

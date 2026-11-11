---
status: accepted
date: 2026-09-10
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0003: Artifact versioning

> Recorded retroactively on 2026-11-11. Independent versioning was explicitly documented
> by `71006bb` and Semantic Versioning by `cb20016` (both 2026-09-10). Artifact-specific
> publishing followed in `dc646ca` that day. The actual decision may have been earlier.

## Context

The shared build configuration and specialized parent POMs can evolve at different rates.
We need a release and versioning policy that lets consumers identify compatible dependencies
without forcing unrelated artifacts to change whenever one component evolves. Releases should
remain understandable and reproducible for consumers.

## Decision

Version `maven-build-config`, `java-parent`, `kotlin-parent`, `kotlin-micronaut-parent` and
`javacard-parent` independently using Semantic Versioning. Each artifact references a specific
version of its dependency. A changed artifact may receive a new version without releasing
unchanged artifacts again.

The dependency chain is `maven-build-config` → `java-parent` → `kotlin-parent` →
`kotlin-micronaut-parent`, with `javacard-parent` depending directly on `java-parent`.

## Consequences

- **Positive:** A JavaCard-only change does not require new versions of unchanged Java or
  Kotlin artifacts; consumers select explicit dependency versions.
- **Negative:** Releases must account for dependency order and compatible version combinations.
- **Risks / neutral:** Independent versioning does not require separate releases every time.
  Coordinated releases remain possible; release policy is documented in the release guide.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Independent semantic versions with explicit dependency references | ✅ | Allows each artifact to evolve without requiring releases of unchanged artifacts |
| Require every artifact to receive a new version for every release | ❌ | Couples unrelated changes and requires releasing unchanged artifacts |

## References

- Git `71006bb`, `cb20016` (2026-09-10): independent versioning and Semantic Versioning rationale.
- Git `dc646ca` (2026-09-10): artifact-specific publishing and release tags.
- Git `cba7b47` (2026-09-11): independent versioning rationale.
- Git `fe3fe98` (2026-09-11) and `c41333d` (2026-09-15): extend the artifact chain to Kotlin and Micronaut.
- Git `0952723` (2026-10-20): prioritize coordinated releases without removing independent versioning.
- [ADR-0004](0004-build-isolation.md): build isolation.

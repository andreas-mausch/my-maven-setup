---
status: accepted
date: 2026-09-15
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0005: Micronaut processor version management

> Recorded retroactively on 2026-11-11. Explicit processor versions were implemented
> with kapt in `c41333d` (2026-09-15), then retained when `ebd742b` switched to KSP
> the same day. Rationale was added in `8de77dc` (2026-09-22) and `dfca19d` (2026-09-23).

## Context

The Micronaut build needs annotation processors whose versions match the selected platform.
We want to keep those versions aligned and avoid unnecessary duplication. The Platform BOM
manages project dependencies, but the processors are plugin dependencies. A normal BOM import
neither manages those dependencies nor exposes its properties to the importing POM, so we need
a separate way to supply compatible processor versions.

## Decision

Mirror the required Micronaut processor versions explicitly in the Kotlin Micronaut parent.
Check them against the imported platform whenever that platform is updated. Treat this
duplication as a temporary workaround.

Replace it with platform-provided properties once a stable Maven release supports mixin
property imports, we can require that release for consumers, and an isolated consumer build
verifies that all required processor versions resolve correctly without local copies and
that compilation and tests pass. Record that replacement in a superseding ADR.

## Consequences

- **Positive:** Processor dependencies are explicit and the Maven/KSP build works without
  relying on properties that a BOM import does not expose.
- **Negative:** Duplicated version declarations can drift from the platform.
- **Risks / neutral:** Returning to kapt would not remove the Maven model limitation.
  Adopting mixins requires raising the Maven minimum version for consumers.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Explicit mirrored versions | ✅ | Works with the current Maven model |
| Ordinary BOM import alone | ❌ | Does not manage plugin dependency versions or import properties |
| Return to kapt | ❌ | The previous kapt setup had the same Maven version duplication limitation |
| Maven mixin | ⏳ | Planned replacement once available in a suitable stable Maven release |

## References

- Git `c41333d`, `ebd742b` (2026-09-15): implementation and kapt-to-KSP migration.
- Git `8de77dc` (2026-09-22), `dfca19d` (2026-09-23): rationale and migration conditions.
- [`parent-kotlin-micronaut.xml`](../../parent-kotlin-micronaut.xml).

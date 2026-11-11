# Decision Records

Architecture Decision Records (ADRs) for this repo, in
[Nygard style](https://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions).

Record significant decisions about build structure, features, quality policies, tools, integration and output conventions,
not routine dependency updates. Usage instructions belong in the getting-started guides and `Features.md`.

## Index

| # | Title | Decision | Status | Date | Supersedes |
|---|-------|----------|--------|------|------------|
| 0001 | [Build tool](0001-build-tool.md) | Maven | ✅ `accepted` | 2025-10-07 (first implementation) | none |
| 0002 | [Build-tool provisioning](0002-build-tool-provisioning.md) | User-installed tools, no wrapper | ✅ `accepted` | 2026-05-16 (first explicit rationale) | none |
| 0003 | [Artifact versioning](0003-artifact-versioning.md) | Independent semantic versions | ✅ `accepted` | 2026-09-10 | none |
| 0004 | [Build isolation](0004-build-isolation.md) | Separate builds, isolated consumers | ✅ `accepted` | 2026-09-11 | none |
| 0005 | [Micronaut processor version management](0005-micronaut-processor-version-management.md) | Explicitly mirror platform versions | ✅ `accepted` | 2026-09-15 (first implementation) | none |
| 0006 | [Database migration integration](0006-database-migration-integration.md) | Keep KSP and Mongock | ✅ `accepted` | 2026-09-23 (first explicit rationale) | none |
| 0007 | [Micronaut Native Image support](0007-micronaut-native-image-support.md) | Defer native artifact support | ✅ `accepted` | 2026-09-23 (first explicit rationale) | none |
| 0008 | [Build report lifecycle and location](0008-build-report-lifecycle-and-location.md) | Generate at verify, use target/reports | ✅ `accepted` | 2026-09-30 | none |
| 0009 | [Kotlin formatting](0009-kotlin-formatting.md) | Spotless with ktlint | ✅ `accepted` | 2026-11-11 | none |

## Status values

| `status` | Icon | Meaning |
|----------|------|---------|
| `proposed` | 🕐 | Researched/recommended, not yet implemented or agreed; **the old decision still applies** |
| `accepted` | ✅ | Decision in effect |
| `rejected` | 🚫 | Proposed, but decided against; never was in effect. Rejected options remain in the accepted ADR's options table |
| `partially-superseded` | ⚠️ | Applies only to areas not taken over by newer records (see `superseded-by`) |
| `superseded` | ~~title~~ | Replaced by a newer record (see `superseded-by`) |
| `deprecated` | 🗑️ | No longer recommended, but not replaced by a specific ADR |

## Conventions

- **One file per decision**, numbered `NNNN-short-slug.md`. Never reuse numbers. Titles use the bare number;
  prose and front-matter references use `ADR-NNNN`.
- **Title = the problem/decision area, not the solution.** A superseding decision answers the same question differently.
- Use **English** titles, file names and records.
- **Records are immutable once Accepted.** A changed decision gets a new ADR. Update the old record's status
  and `superseded-by`, and the new record's `supersedes`. Dated research snapshots may be appended;
  do not rewrite the accepted Decision section. Editorial fixes that do not change meaning are allowed.
- Copy [`template.md`](template.md), take the next number and add an index row. Omit unused optional sections.
- Keep YAML metadata and the index in sync. Conditions and caveats belong in prose below the title.
- **Context** explains the problem, motivation, goals and constraints that call for a decision.
  **Decision** states the chosen approach; **Options considered** explains why it was selected
  over alternatives; **Consequences** describes what follows from that choice.

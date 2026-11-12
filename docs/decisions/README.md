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
| 0010 | [Artifact signing](0010-artifact-signing.md) | Optional detached GPG signatures | ✅ `accepted` | 2026-05-09 | none |
| 0011 | [Test separation](0011-test-separation.md) | Surefire units, Failsafe integration tests | ✅ `accepted` | 2026-05-12 | none |
| 0012 | [Software bill of materials](0012-software-bill-of-materials.md) | CycloneDX and SPDX JSON | ✅ `accepted` | 2026-05-12 | none |
| 0013 | [Application packaging](0013-application-packaging.md) | Executable shaded main JAR | ✅ `accepted` | 2026-05-12 | none |
| 0014 | [Dependency license policy](0014-dependency-license-policy.md) | FOSS allowlist, explicit JavaCard exception | ✅ `accepted` | 2026-05-12 | none |
| 0015 | [Vulnerability scanning policy](0015-vulnerability-scanning-policy.md) | Grype; dependencies block, image findings warn | ✅ `accepted` | 2026-05-14 | none |
| 0016 | [Optional build capabilities](0016-optional-build-capabilities.md) | Individual profiles, no current aggregate | ✅ `accepted` | 2026-05-17 | none |
| 0017 | [Artifact size optimization](0017-artifact-size-optimization.md) | Optional ProGuard, framework-specific safeguards | ✅ `accepted` | 2026-05-17 | none |
| 0018 | [Kotlin annotation processing](0018-kotlin-annotation-processing.md) | KSP instead of kapt | ✅ `accepted` | 2026-09-15 | none |
| 0019 | [Integration test infrastructure](0019-integration-test-infrastructure.md) | Real services through Test Resources | ✅ `accepted` | 2026-09-15 | none |
| 0020 | [External API simulation](0020-external-api-simulation.md) | WireMock for external HTTP APIs | ✅ `accepted` | 2026-09-17 | none |
| 0021 | [API documentation](0021-api-documentation.md) | Generated OpenAPI, interactive RapiDoc | ✅ `accepted` | 2026-09-22 | none |
| 0022 | [Application health signals](0022-application-health-signals.md) | Health, liveness and readiness endpoints | ✅ `accepted` | 2026-09-22 | none |
| 0023 | [Container deployment](0023-container-deployment.md) | Runtime image, non-root, liveness check | ✅ `accepted` | 2026-09-22 | none |
| 0024 | [Compiler warning policy](0024-compiler-warning-policy.md) | Warnings fail by default | ✅ `accepted` | 2026-09-23 | none |
| 0025 | [Build report portability](0025-build-report-portability.md) | Self-contained HTML, retained raw outputs | ✅ `accepted` | 2026-09-30 | none |
| 0026 | [HTTP error representation](0026-http-error-representation.md) | RFC 9457 Problem Details | ✅ `accepted` | 2026-10-03 | none |
| 0027 | [Code coverage measurement](0027-code-coverage-measurement.md) | Informational JaCoCo report, no percentage gate | ✅ `accepted` | 2026-05-12 | none |
| 0028 | [Test reporting evaluation](0028-test-reporting-evaluation.md) | Evaluate optional Allure; adoption undecided | 🕐 `proposed` | 2026-11-12 | none |

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

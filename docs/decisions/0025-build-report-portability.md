---
status: accepted
date: 2026-09-30
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0025: Build report portability

> Recorded retroactively on 2026-11-11. License/test reports began in September; standalone
> source coverage followed in November. Lifecycle and location are separate in ADR-0008.

## Context

People need readable build results that can be opened locally, used offline and shared without
deploying a website or carrying an entire report directory. Raw tool results should remain
available for machine consumption rather than being replaced by HTML alone.

Platforms such as GitHub and GitLab often offer similar or more extensive reporting features.
However, relying on their interfaces and integrations can create vendor lock-in, and some
capabilities are restricted to paid plans. We want the report functionality to remain usable
without a particular hosting provider, account or subscription, including after moving the
repository elsewhere.

## Decision

Provide self-contained HTML reports with their required presentation assets embedded, no
external runtime asset dependencies, and local searching where supported. Keep canonical
machine-readable tool outputs alongside their existing workflows. Retain JaCoCo XML and CSV
outputs, but do not generate its original multi-file HTML report; the standalone coverage
report provides the readable view. This output choice was updated on 2026-11-11.

Provide the following report types for distinct inspection needs:

| Report type | Purpose |
|-------------|---------|
| [Unit tests](0011-test-separation.md) | Inspect test results and diagnose failures quickly |
| [Integration tests](0011-test-separation.md) | Assess integrated workflow results separately from unit tests |
| [Coverage](0027-code-coverage-measurement.md) | Identify code not exercised by tests and guide additional testing |
| [Dependency licenses](0014-dependency-license-policy.md) | Review dependency licenses in a readable overview |
| [Dependency vulnerabilities](0015-vulnerability-scanning-policy.md) | Inspect security findings in the project's dependencies |
| [Container vulnerabilities](0015-vulnerability-scanning-policy.md) | Make findings across the complete image, including its base image, visible |

These purposes complement the individual feature decisions; this ADR records the shared
presentation and portability approach, not a separate architecture decision for each HTML file.

Keep the reports independent of hosting-platform reporting services. Platforms may store or
distribute the generated files, but opening, searching and inspecting them must not require
the platform's reporting UI or a paid feature.

## Consequences

- **Positive:** The custom reports are usable offline and can be shared as individual files.
  Their inspection functionality is independent of hosting-provider accounts, reporting UIs
  and paid plans, reducing vendor lock-in when changing providers.
- **Negative:** Templates and embedded presentation code require maintenance; embedding content
  can produce larger files.
- **Risks / neutral:** Self-contained does not mean safe to publish. The standalone coverage
  report includes source code, and other reports reveal dependency or vulnerability information.
  Review contents and handle untrusted report data safely.
  This independence applies to report inspection, not to every project service: the current
  CI and artifact distribution still use GitHub, and report generation requires its build tools.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Standalone custom HTML with retained raw outputs | ✅ | Matches the documented offline and single-file sharing goals |
| JaCoCo XML and CSV outputs | Retained additionally | Preserves machine-readable coverage data and the input for the standalone report |
| Original multi-file JaCoCo HTML report | Not retained | Duplicates the readable coverage view without meeting the single-file sharing goal |
| Rely exclusively on GitHub, GitLab or another platform's reporting features | ❌ | May offer similar or better functionality, but couples inspection to a provider and potentially paid capabilities |

The author clarified the hosting-independence motivation during reconstruction on 2026-11-11.
No platform benchmark or pricing comparison is claimed.

## References

- Git `61860d7`, `e04a5ee` (2026-09-30): self-contained license and test reports.
- Git `e8acbd2` (2026-11-04): standalone source-coverage report.
- [Reports](../../Features.md#reports).
- [ADR-0008](0008-build-report-lifecycle-and-location.md): lifecycle and output location.

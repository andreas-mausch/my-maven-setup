---
status: accepted
date: 2026-09-30
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0008: Build report lifecycle and location

> Recorded retroactively on 2026-11-11. `61860d7` (2026-09-30) implements and documents
> the convention. Coverage and license-text output followed on 2026-10-02; these later
> extensions are identified below rather than attributed to the initial implementation.

## Context

The project produces human-readable license, test and other build reports. We want portable
outputs available from a normal verification build without requiring a full documentation
site. As more reports are added, we need a consistent lifecycle and output location that users
and CI can discover without confusing build artifacts with Maven Site pages.

## Decision

Generate build reports through normal build-plugin executions, independently of `mvn site`.
Define `${build.reports.directory}`, defaulting to `${project.build.directory}/reports`.
Place self-contained human-readable reports directly there with descriptive names; use
subdirectories only for reports with supporting files.

Keep canonical machine-readable outputs in established tool-specific locations such as
`target/surefire-reports`. The current license text report is explicitly placed beside its HTML
report, rather than treated as generated source output.

## Consequences

- **Positive:** Directory and lifecycle communicate the actual purpose of the reports.
  Reports can be used without generating or deploying a Maven Site.
- **Negative:** Introduces a project-specific directory property and requires CI checks and
  consumers of report paths to follow the convention.
- **Risks / neutral:** This is a semantic choice, not a technical restriction. Build plugins
  could write to `${project.reporting.outputDirectory}` without running the Site lifecycle.

## Options considered

The initial design reused `${project.reporting.outputDirectory}`, which defaults to
`${project.build.directory}/site`. Its name appears suitable and using a Maven-provided
property avoids a custom convention. However, it belongs to Maven's `<reporting>` configuration,
and the Site Plugin uses that directory for the site and reports generated during `mvn site`.

| Option | Verdict | Why |
|--------|---------|-----|
| Dedicated `target/reports` convention | ✅ | Communicates build-report purpose accurately |
| Reuse `${project.reporting.outputDirectory}` | ❌ | Avoids a custom property, but misleadingly suggests Maven Site integration |

## References

- Git `61860d7` (2026-09-30): report directory convention and license HTML implementation.
- Git `63afb08` (2026-10-02): move coverage output into the report directory.
- Git `a97ec22` (2026-10-02): place license text beside HTML and update the rationale.
- [`Features.md`](../../Features.md): current report outputs and usage.

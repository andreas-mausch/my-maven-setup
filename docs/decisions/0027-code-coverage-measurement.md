---
status: accepted
date: 2026-05-12
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0027: Code coverage measurement

> Recorded retroactively on 2026-11-11. JaCoCo was introduced in May; the author clarified
> the purpose of coverage and rejection of fixed thresholds during this reconstruction.

## Context

Developers can overlook test cases or code paths. They need a way to inspect which code their
tests have exercised and decide where additional tests would be useful. A single percentage
does not establish whether important behaviour is tested or whether the tests are meaningful.

## Decision

Offer JaCoCo coverage measurement through the optional `coverage` profile and provide a readable
report, including source-level coverage where sources are available. Use coverage as information
for developers to identify overlooked cases and make their own decisions about improving tests.

Do not enforce a fixed minimum coverage percentage or fail the build for falling below a
coverage target. A threshold such as 80% is not our definition of adequate testing and should
not replace judgment about which behaviours need tests.

## Consequences

- **Positive:** Developers can inspect unexercised code and target additional tests without
  being pushed to meet an arbitrary percentage.
- **Negative:** The report requires interpretation; it does not automatically require tests
  for important uncovered behaviour.
- **Risks / neutral:** Executing code does not prove that assertions verify its behaviour.
  High coverage is not a quality guarantee, and low coverage alone does not identify the
  most valuable next test. Instrumentation and reporting add optional build work.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Informational coverage report | ✅ | Helps developers notice missed cases and decide where tests need improvement |
| Fixed percentage gate | ❌ | The author rejects arbitrary coverage limits as a substitute for assessing meaningful tests |
| No coverage report | Not selected | Removes a useful way to discover code paths that tests did not exercise |

## References

- Git `5257f1e` (2026-05-12): JaCoCo coverage measurement.
- Git `3769d95` (2026-05-17): optional coverage profile.
- [Coverage usage](../../Features.md#code-coverage).
- [ADR-0025](0025-build-report-portability.md): report presentation.

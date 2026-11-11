---
status: accepted
date: 2026-05-17
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0016: Optional build capabilities

> Recorded retroactively on 2026-11-11. Optional profiles existed earlier; the selected date
> records the coverage opt-in change and explicit removal of the aggregate release profile.
> The author no longer recalls why that aggregate profile was reverted; its absence is not
> a permanent rejection of the idea.

## Context

Daily builds and full CI verification have different needs. Instrumentation, reports, signing,
external tools and optimization can add runtime or setup requirements that are unnecessary
for a quick development build. Consumers need to choose those capabilities independently.

## Decision

Expose additional capabilities through individual profiles such as `coverage`, `sbom`,
`license-check`, `sign`, `linting`, `size-optimization` and `vulnerability-report`. Select
the required profiles explicitly in CI. There is currently no aggregate `release` profile;
this is not a prohibition on adding one. An aggregate profile would
be welcome if it can compose the existing capabilities simply and without duplicating their
build configuration. Revisit it when such an integration is available.

This does not make every feature opt-in: normal tests and automatically activated test reports
retain their documented lifecycle behaviour.

## Consequences

- **Positive:** Consumers control build cost and prerequisites without enabling unrelated capabilities.
- **Negative:** Full verification requires an explicit profile list, and an omitted profile
  can mean a quality check never ran.
- **Risks / neutral:** Optional checks are not guaranteed by an unqualified `mvn verify`.
  Faster development builds are a documented reason for coverage opt-in. The aggregate profile
  could be reconsidered independently without removing the individual profiles.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Individual capability profiles | ✅ | Allows independent selection and lighter development builds |
| Coverage always active | ❌ | The migration commit explicitly seeks faster unadorned builds |
| Aggregate release profile | Absent currently, open to reconsideration | Implemented and reverted on the same day; the author no longer remembers the reason and would accept simple composition without repeated configuration |

## References

- Git `3769d95` (2026-05-17): coverage opt-in for faster development builds.
- Git `58eb489`, `43ae182` (2026-05-17): aggregate release profile and its reversal.
- Git `b1cb3b4` (2026-05-18): opt-in linting.
- [`Features.md`](../../Features.md): capability activation.

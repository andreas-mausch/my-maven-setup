---
status: accepted
date: 2026-05-12
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0014: Dependency license policy

> Recorded retroactively on 2026-11-11 from the allowlist implementation and documentation.

## Context

Consumers need visibility into dependency licenses and a build-time check against the project's
permitted-license policy. Missing metadata and differently spelled license names must not
silently remove dependencies from that inspection. JavaCard also requires a proprietary SDK.

## Decision

Offer a `license-check` profile using the License Maven Plugin with a FOSS-oriented allowlist,
normalized license aliases and failure on missing or forbidden license metadata. Supply license
overrides for metadata that cannot be resolved normally. Permit the Oracle JavaCard SDK license
as an explicit JavaCard-specific exception, not a general expansion of the Java/Kotlin policy.

## Consequences

- **Positive:** License information and explicit exceptions become visible and automatically checked.
- **Negative:** Metadata repair and alias maintenance require work; an allowlist cannot replace
  legal assessment of actual usage or obligations.
- **Risks / neutral:** The current plugin can accept a multiply licensed dependency if any listed
  license is permitted, even when another is unknown or forbidden. Maven metadata does not reliably
  express license `AND`/`OR` semantics. The current check therefore does not fully establish that
  every declared license is known and permitted; that limitation needs a separate policy refinement.

## Options considered

The allowlist and JavaCard exception are documented; no tool comparison or legal review is claimed.

## References

- Git `69644fb` (2026-05-12): FOSS allowlist and override mechanism.
- Git `094da38` (2026-09-10): packaged JavaCard license metadata.
- [License checking](../../Features.md#license-check).
- [`parent-java.xml`](../../parent-java.xml): plugin configuration.

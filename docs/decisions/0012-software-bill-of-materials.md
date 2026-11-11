---
status: accepted
date: 2026-05-12
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0012: Software bill of materials

> Recorded retroactively on 2026-11-11; the author clarified the original two-format motivation.

## Context

Dependency information is needed for security scanning and license/compliance inspection.
It should be available as machine-readable build output rather than requiring consumers to
extract information from human-readable reports.

The original motivation for offering two formats was the author's reading that CycloneDX
focused more on security scanning and SPDX more on licensing. The aim was to cover both use
cases. The author is now less certain about that distinction; it is the historical motivation,
not a claim that either format is limited to one domain.

## Decision

Generate JSON SBOMs in both CycloneDX and SPDX format during `package`, activated by the `sbom`
profile. Feed CycloneDX into the current security-scanning workflow and exclude test dependencies.
Provide SPDX for license/compliance-oriented consumption and include all scopes as supported by
the generator. Name outputs using the artifact ID, version and format.

## Consequences

- **Positive:** Consumers receive two established formats for different downstream workflows.
  Grype can scan the CycloneDX output directly.
- **Negative:** Two generators and outputs require maintenance and schema verification.
  Different scope coverage means the files are not interchangeable inventories.
- **Risks / neutral:** A generator's supported scopes and metadata quality constrain the output;
  declaring all scopes does not guarantee a perfectly complete inventory. SBOMs do not certify
  security or license compliance. The initial security-versus-licensing distinction is not
  an exclusive division of format capabilities; downstream-tool compatibility is what matters.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Provide both CycloneDX and SPDX | ✅ | Originally intended to cover both security-scanning and licensing use cases |
| Select only one format | Not selected | The initial motivation favoured covering both perceived focus areas; this is not proof that one format could not serve both |

## References

- Git `44c1ee7`, `84d562d` (2026-05-12): dual generators and optional profile.
- Git `bd7d162` (2026-09-13): CI schema validation.
- [SBOM formats and scopes](../../Features.md#software-bill-of-materials).
- [ADR-0015](0015-vulnerability-scanning-policy.md): vulnerability policy.

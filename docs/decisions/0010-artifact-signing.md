---
status: accepted
date: 2026-05-09
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0010: Artifact signing

> Recorded retroactively on 2026-11-11 from the signing implementation and verification
> documentation. The author clarified the motivation and alternative during this reconstruction.

## Context

Consumers need a way to verify that a project artifact was signed by the expected key and has
not changed since signing. The author considers artifact signing good practice and wants the
shared parent to make it available without each consumer having to recreate the integration.
Signing must cover attached artifacts as well as the main artifact.

## Decision

Provide GPG signing as a standard capability of the parent through the opt-in `sign` profile.
This makes signing available by default, not automatically active in every build.
Select the signing key explicitly and produce detached `.asc` signatures for the consumer
POM and generated or attached project artifacts. Verify signatures in CI with the exported
public key in a separate verification home.

## Consequences

- **Positive:** Artifact integrity and signing-key identity can be checked independently.
- **Negative:** Signing requires key provisioning and protection; users must establish which
  public key they trust.
- **Risks / neutral:** A valid signature does not prove that the artifact is safe, free of
  vulnerabilities or reproducibly built. The CI demonstration key is not an independent trust anchor.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Provide reusable signing support in the parent | ✅ | Signing artifacts is good practice and should not require repeated consumer configuration |
| Offer no signing capability | ❌ | Leaves consumers to implement that practice themselves or omit it |

GPG is the implemented integration; no historical comparison with other signing technologies
is claimed.

## References

- Git `57f9109` (2026-05-09): signing profile.
- Git `baadebb` (2026-05-09): signing attached JavaCard CAP files.
- Git `c8c234f` (2026-05-12): signature verification instructions.
- Git `2d24b7d` (2026-09-13): CI signature verification.
- [Signing usage](../../Features.md#signing).

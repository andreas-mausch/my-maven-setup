---
status: accepted
date: 2026-09-22
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0023: Container deployment

> Recorded retroactively on 2026-11-11 from the Dockerfile and the author's deployment goal.

## Context

The build should produce something runnable at the end, not merely source code or a library
that needs further assembly before deployment. The author wants a ready-to-run application
artifact; the container packages the executable JAR together with its Java runtime. This does
not require a native executable, whose current restrictions are covered separately in ADR-0007.
The runtime image should exclude development tooling and not require root privileges.

## Decision

Package the built executable Micronaut JAR in a pinned Java runtime image, without including
the compiler or Maven build environment. Run it as a non-root user and include a liveness health check.
Build the image in CI and inspect it through the vulnerability-scanning policy.

## Consequences

- **Positive:** Provides an explicit, repeatable runtime packaging recipe and reduces privileges
  compared with running the application as root.
- **Negative:** The base image and runtime need updates; image packaging does not provision
  the external database or broker.
- **Risks / neutral:** Pinning improves version control but can retain known vulnerabilities.
  A version tag does not guarantee immutable image contents; digest pinning would be a stronger
  reproducibility constraint than the current tag-based reference.
  Non-root execution and a health check are safeguards, not proof of production security.
  Container vulnerability findings are currently warnings under ADR-0015.

## Options considered

A runtime container is the selected delivery form. The author did not identify a specific
alternative when clarifying the goal; no packaging-tool comparison is claimed.

## References

- Git `2ad77dc`, `1768fdb` (2026-09-22): container design and CI build.
- [Dockerfile](../../examples/kotlin-micronaut/Dockerfile).
- [ADR-0015](0015-vulnerability-scanning-policy.md): image scanning policy.
- [ADR-0022](0022-application-health-signals.md): probe semantics.
- [ADR-0007](0007-micronaut-native-image-support.md): native executable support.

---
status: accepted
date: 2026-09-17
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0020: External API simulation

> Recorded retroactively on 2026-11-11 from the webhook implementation and offline-test rationale.

## Context

The order workflow invokes an external HTTP webhook. Integration tests should not depend on
live third-party availability, credentials, changing responses or network access to that service.
They still need to inspect the HTTP requests produced by the application.

## Decision

Simulate external HTTP APIs with WireMock during integration tests and verify the expected
outbound requests. Keep this boundary simulation distinct from the real database and broker
infrastructure. Support offline test runs once Maven dependencies, tools and required container
images are already available locally.

## Consequences

- **Positive:** Tests control external responses and can inspect webhook requests without
  calling a live external API.
- **Negative:** Simulations require maintenance and may diverge from the provider's real contract.
- **Risks / neutral:** Offline capability assumes prerequisites are cached; a fresh checkout
  on a machine without dependencies or images is not an offline build. Simulation does not
  replace provider compatibility testing when that is needed.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Simulate external HTTP APIs | ✅ | Removes live-system dependencies and gives tests controlled responses |
| Call live external APIs in routine integration tests | ❌ | Conflicts with the documented deterministic and offline-test goals |

No simulation-tool comparison is recorded.

## References

- Git `e8e613d`, `53b2c98` (2026-09-17): webhook and test-scoped WireMock resources.
- Git `31cd3bc` (2026-09-22): offline API simulation rationale.
- [External API simulation](../../Features.md#offline-builds-and-external-api-simulation).

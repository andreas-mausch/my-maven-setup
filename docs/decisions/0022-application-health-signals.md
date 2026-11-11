---
status: accepted
date: 2026-09-22
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0022: Application health signals

> Recorded retroactively on 2026-11-11 from the implementation and the author's operational goals.

## Context

We want automated checks of whether services are functioning and a way for Docker to report
the application's health status. An existing process alone is not enough for those checks.
The signals should also distinguish application liveness from readiness to accept traffic.

## Decision

Expose health, liveness and readiness through Micronaut Management. Use the liveness endpoint
for the example container's health check. Exclude routine health probes from HTTP access logs
and verify the health endpoints in integration tests.

## Consequences

- **Positive:** Tooling can query explicit health signals without relying on business endpoints.
  Routine probes do not dominate the access log.
- **Negative:** Health definitions and endpoint exposure need review for the deployment environment.
- **Risks / neutral:** Liveness and readiness serve different purposes. Docker health status
  alone does not define restart or traffic-routing behaviour, and a liveness check is not
  evidence that every application dependency or workflow is ready.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Explicit health endpoints through Micronaut Management | ✅ | Supports automated service checks and Docker health status |
| Offer no dedicated health signal | ❌ | Does not provide the desired automatic service-health checks |

No custom-endpoint comparison is recorded.

## References

- Git `ac91e39` (2026-09-22): health endpoints.
- Git `2ad77dc` (2026-09-22): liveness check in the container.
- [Application health](../../Features.md#application-health).
- [ADR-0023](0023-container-deployment.md): container packaging.

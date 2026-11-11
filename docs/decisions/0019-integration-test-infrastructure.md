---
status: accepted
date: 2026-09-15
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0019: Integration test infrastructure

> Recorded retroactively on 2026-11-11 from the Test Resources migration and its documented goals.

## Context

The Micronaut example integrates a database and a message broker. Its tests need to exercise
the real service behaviour, connection configuration and asynchronous workflow rather than
only the application's interactions with test doubles. Developers should not have to manually
provision those services for each integration-test run.

## Decision

Run integration tests against real MongoDB and RabbitMQ services. Use Micronaut Test Resources
with Testcontainers to provision infrastructure when the required connection properties are
missing. Start and stop Test Resources through the managed Micronaut Maven plugin.

## Consequences

- **Positive:** Tests exercise real infrastructure and can provision it automatically.
  Integration failures that would otherwise surface only on servers can potentially be
  discovered much earlier, during local development or CI.
- **Negative:** Runs require a compatible container runtime, images, startup time and additional resources.
- **Risks / neutral:** Containers improve isolation but do not guarantee deterministic asynchronous
  timing or reproduce every production configuration. Supplying external connection properties
  changes provisioning behaviour and requires care about the target environment.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Real services provisioned with Test Resources/Testcontainers | ✅ | Exercises service behaviour without manual per-run provisioning |
| Mock database and broker behaviour | Not used for these integration tests | Does not exercise the actual infrastructure integrations described by the example |

## References

- Git `9325f21`, `c84f50c` (2026-09-15): Test Resources and Testcontainers documentation.
- Git `07e52fd` (2026-09-22): real-infrastructure rationale.
- [Real integration infrastructure](../../Features.md#integration-tests-with-real-infrastructure).
- [ADR-0020](0020-external-api-simulation.md): external API boundary.

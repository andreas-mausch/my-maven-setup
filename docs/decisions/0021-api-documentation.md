---
status: accepted
date: 2026-09-22
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0021: API documentation

> Recorded retroactively on 2026-11-11; the author considers API documentation essential.

## Context

An API exists to be used, and consumers need documentation to understand how to use it.
The author therefore considers API documentation a must-have rather than an optional convenience.
It should be discoverable and stay aligned with the controllers and models as the API changes.

## Decision

Provide API documentation as part of the example. Generate an OpenAPI specification at compile
time from Micronaut controllers and API models. Serve the generated specification and interactive
RapiDoc documentation from the example, and verify documentation endpoints in integration tests.

## Consequences

- **Positive:** API documentation is derived from the implementation and available interactively.
- **Negative:** Processors and annotations require maintenance; exposing documentation may
  require deployment-specific access decisions.
- **Risks / neutral:** Generated schemas still depend on accurate models and annotations.
  Generation is not proof that every runtime response conforms to the specification.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Generate OpenAPI from implementation | ✅ | The documented goal is keeping API description and implementation aligned |
| Offer no API documentation | ❌ | Consumers need to understand the API; documentation is a must-have for the author |
| Maintain an independent description manually | Not adopted | Would require separately keeping it synchronized |

For the interactive viewer, the author prefers RapiDoc's UI based on prior experience with
Swagger UI. This is a subjective presentation preference, not a claim of technical superiority.

| Viewer | Verdict | Why |
|--------|---------|-----|
| RapiDoc | ✅ | The author finds its UI more attractive |
| Swagger UI | ❌ | Familiar from prior use, but its UI is less appealing to the author |

## References

- Git `d5634b6` (2026-09-22): generated API documentation.
- [API documentation endpoints](../../Features.md#generated-api-documentation).

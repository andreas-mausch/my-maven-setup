---
status: accepted
date: 2026-10-03
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0026: HTTP error representation

> Recorded retroactively on 2026-11-11 from the implementation and the author's alternatives.

## Context

HTTP clients need structured error responses they can interpret consistently rather than
relying on arbitrary text or unrelated response shapes. Request validation failures should
follow the same recognizable representation as other framework-processed errors.

## Decision

Use RFC 9457-compatible Problem Details with the `application/problem+json` media type for
errors processed by Micronaut in the example. Include structured status and title information,
and verify the representation for request validation errors in integration tests.

## Consequences

- **Positive:** Clients can consume a standard error representation instead of an example-specific envelope.
- **Negative:** Configuration and tests must preserve the media type and expected fields.
- **Risks / neutral:** The documented scope is framework-processed errors, not a guarantee
  about every network, proxy or infrastructure failure. The format does not by itself define
  domain-specific error codes or justify exposing internal exception details.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| RFC 9457 Problem Details | ✅ | Provides a standardized error representation independent of a framework-specific format |
| Micronaut's built-in default error representation | ❌ | Provides an existing framework-specific format rather than the selected standard |
| Custom error handling and representation | ❌ | Would require defining and maintaining our own contract instead of using an established standard |

This decision concerns the externally visible error representation; using Micronaut's error
processing infrastructure does not require keeping its default response format.

## References

- Git `30b3f64` (2026-10-03): Micronaut Problem Details.
- [HTTP Problem Details](../../Features.md#http-problem-details).
- [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457.html).

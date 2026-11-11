---
status: accepted
date: 2026-05-12
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0011: Test separation

> Recorded retroactively on 2026-11-11 from the test configuration and documented commands.
> The author clarified the convention trade-off during this reconstruction.

## Context

Developers need to run unit tests separately from tests requiring an integrated application
or external infrastructure. Full verification must still run both suites, with their results
and failures clearly attributable to the appropriate suite. The author dislikes imposed test
class naming conventions and would prefer a separation requiring neither special names nor
an extra package, but has not found a suitable solution within this setup.

## Decision

Use Surefire for unit tests during `test` and Failsafe for integration tests during
`integration-test` and `verify`. Classify integration tests using packages containing
`.integration.`. Register their additional sources and resources through Build Helper.
Consumers activate the inherited integration-test plugin configurations explicitly.
Accept the extra package convention as the less objectionable compromise compared with
requiring an `IT` filename suffix. Revisit the selection mechanism if a practical approach
without a class naming convention or extra package becomes available.

## Consequences

- **Positive:** `mvn test` provides a unit-only run; `mvn verify` executes both configured suites.
  Canonical reports remain separate.
- **Negative:** Package placement determines execution, so incorrectly classified tests may
  run in the wrong suite. Consumers must activate and maintain the integration-test setup.
- **Risks / neutral:** Separate source directories alone do not determine test selection;
  the package-based include/exclude rules must remain consistent.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Separate suites selected by `.integration.` packages | ✅ | The extra package is undesirable, but the author prefers it to imposed class names |
| Run all tests through the unit-test runner, with integration tests named `*IT.java` | ❌ | Does not provide the desired separate lifecycle; the author also finds the naming convention unattractive |
| Separate suites without a naming convention or extra package | Preferred, not found | No suitable solution was found for this setup; this does not claim that such a solution is impossible |

## References

- Git `db5ef88` (2026-05-12): package-based unit/integration separation.
- Git `b6d834a` (2026-05-12): consumer activation through plugin management.
- [Test commands and selection](../../Features.md#run-tests).

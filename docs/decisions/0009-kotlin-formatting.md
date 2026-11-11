---
status: accepted
date: 2026-11-11
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0009: Kotlin formatting

> Migrated to ADR format on 2026-11-11 from the rationale recorded with `fd49d94` that day.
> ktfmt was used previously, but no separate predecessor ADR exists.

## Context

Spotless already integrates Kotlin formatting checks and corrections into Maven. We want
consistent formatting without forcing readable code into unnecessarily rigid layouts. Authors
should retain selected layout choices, and consumers should be able to adapt the suggested
style without replacing the Maven integration or having their project settings ignored.

## Decision

Keep Spotless and replace its Kotlin formatter with ktlint. Package fallback defaults in
`maven-build-config` and load `ktlint.editorconfig` through Spotless's `editorConfigPath` as
`EditorConfigDefaults`, not forced overrides. Consumer `.editorconfig` settings take precedence,
including a single-setting override with `root = true`.

Provide `intellij_idea` style, two-space indentation, LF line endings and no trailing commas
as fallback defaults. Set no maximum line length and disable class and function signature
layout rules by default to retain compact DSL calls and deliberately chosen expression-body
line breaks. Keep remaining standard rules for spacing, imports and redundant syntax.

Consumers may override individual settings in their `.editorconfig`. Settings not specified
there retain the parent fallback values; settings absent from both use ktlint's own defaults.
When the `linting` profile is active, these effective settings are applied and checked, not
merely recommended.

Disable Spotless's up-to-date index in Kotlin consumers. Java Eclipse JDT and POM Eclipse WTP
formatting, and the opt-in `linting` profile, remain unchanged.

## Consequences

- **Positive:** Less layout rewriting and configurable consumer preferences without copying
  parent configuration into each project. A shared parent suggests style rather than defeating
  consumer choices.
- **Negative:** Some layout choices remain with the author, so output is less uniform.
  IDEs do not discover defaults inside Maven artifacts; projects must declare desired IDE
  settings in their own `.editorconfig`. Disabling the plugin-level index also rechecks
  inherited Java/POM formats, increasing formatting work.
- **Risks / neutral:** ktlint does not support every IntelliJ option and can still enforce
  layout rules. Compiler warnings and other quality gates are unchanged: ktfmt was not a
  semantic analyzer. Detekt would be a separate decision.

## Options considered

The existing rationale cites ktfmt's extensive wrapping and deeper indentation around Kotest
superclass lambdas in a consuming project. This repository's examples use JUnit 5 and AssertJ,
not Kotest. ktlint supports targeted rules and EditorConfig, including selected IntelliJ
properties, allowing the specific layout restrictions to be relaxed.

| Option | Verdict | Why |
|--------|---------|-----|
| ktlint with packaged fallback defaults | ✅ | Configurable rules with consumer authority |
| Keep ktfmt | ❌ | Too rigid for the desired style; still reasonable for projects prioritizing uniform output |
| Supply defaults through `editorConfigOverride` | ❌ | Overrides consumer choices rather than providing fallback settings |
| Copy suggested settings into consumers | ❌ | Adds setup work and risks replacing existing configuration |
| Retain Spotless's up-to-date index | ❌ | Changing only a consumer's `.editorconfig` did not reliably invalidate cached source checks during verification |

## References

- Git `fd49d94` (2026-11-11): migration, formatter defaults, example override and validation.
- [`parent-kotlin.xml`](../../parent-kotlin.xml).
- [Shared defaults](../../maven-build-config/src/main/resources/de/neonew/maven/ktlint.editorconfig).
- [Consumer override](../../examples/kotlin/.editorconfig).
- [Formatting usage](../../Features.md#code-formatting).

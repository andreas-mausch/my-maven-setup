---
status: accepted
date: 2025-10-07
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0001: Build tool

> Recorded retroactively on 2026-11-11. Maven is present in the first retained commit,
> `d2faa54` (2025-10-07); the original choice may predate this history. The explicit rationale
> was recorded in the README by `1a49fd9` (2026-05-16). The date is implementation evidence,
> not a recovered approval date. Tool comparisons below describe the author's experience.

## Context

The project needs a build tool for Java and Kotlin projects and a way to reuse shared build
configuration without repeating it in every consumer. The author wants stable, maintainable
build descriptions, well-supported plugins and little upgrade friction when moving to newer
tool or JDK versions. We need to choose between the established build tools and more specialized
alternatives without introducing unnecessary maintenance work.

## Decision

Use Maven and its plugin model for the Java and Kotlin builds.

## Consequences

- **Positive:** Stable POM structure and explicit plugin configuration; newer Maven versions can
  generally run older builds without rewriting their descriptions.
- **Negative:** Large XML files are verbose and harder to maintain; Maven can feel dated.
- **Risks / neutral:** This is a personal preference, not a claim that Maven is superior for
  every project or that Gradle's daemon has no measurable benefit in other environments.
  How Maven is installed and which versions are required is a separate decision in ADR-0002.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Maven | ✅ | Fits the author's stability and plugin-model preferences |
| Gradle | ❌ | The author dislikes programmable build scripts and has experienced upgrades requiring rewrites, plugin incompatibilities and temporary blockers with new Java releases; default daemon behaviour also conflicts with their preferences |
| Niche build tools | Not selected | The existing rationale says no preferable alternative was found, but does not identify individual tools or a systematic comparison |

Maven Polyglot / YAML is an alternative representation of a Maven build, not a competing build
tool. The original rationale expresses interest in YAML but does not decide to adopt Polyglot.

## References

- Git `d2faa54` (2025-10-07): first retained Maven example.
- Git `0451258` (2025-10-07): explain shared and project-specific POM configuration.
- Git `1a49fd9` (2026-05-16): record the explicit Maven preference and alternative-tool rationale.
- Git `cba7b47` (2026-09-11): preserve the original rationale in `Decisions.md`.
- [ADR-0002](0002-build-tool-provisioning.md): build-tool provisioning and version requirements.

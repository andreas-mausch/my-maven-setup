---
status: accepted
date: 2026-05-16
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0002: Build-tool provisioning

> Recorded retroactively on 2026-11-11. The explicit rationale against a Maven Wrapper is
> recorded in the README by `1a49fd9` (2026-05-16); the decision may predate that documentation.
> Split from the build-tool selection during ADR migration and placed directly after it.
> This does not supersede ADR-0001.

## Context

After choosing Maven, we still need to decide how developers obtain it and how builds establish
their Maven and JDK requirements. The author wants tool installation to be explicit and under
the user's control. Unsupported old versions should produce clear errors without requiring
every project to manage its own tool installation.

## Decision

Use user-installed Maven and JDKs rather than distributing a Maven Wrapper or JDK wrapper.
Use the Maven Enforcer Plugin to check the required minimum versions.

## Consequences

- **Positive:** Tool installation remains separate from project configuration; projects do not
  maintain wrapper scripts or project-specific Maven distributions.
- **Negative:** Initial setup is the user's responsibility rather than a wrapper's. Developers
  may use different compatible Maven versions instead of one pinned distribution.
- **Risks / neutral:** Minimum-version checks do not guarantee identical tool versions. The
  preference relies on Maven's generally stable POM model and compatibility with older builds.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| User-installed tools and Enforcer version checks | ✅ | Keeps installation under user control while rejecting unsupported versions |
| Maven Wrapper | ❌ | Per-project Maven provisioning does not match the author's installation preference |
| JDK wrapper | ❌ | The original rationale applies the same user-installation preference to the JDK |

## References

- Git `1a49fd9` (2026-05-16): explicit Maven/JDK installation preference and Enforcer rationale.
- Git `cba7b47` (2026-09-11): move that rationale to `Decisions.md`.
- [ADR-0001](0001-build-tool.md): build-tool selection.
- [Requirements](../../README.md#requirements).

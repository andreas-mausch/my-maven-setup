---
status: accepted
date: 2026-05-12
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0013: Application packaging

> Recorded retroactively on 2026-11-11. Main-artifact naming and Micronaut support are later
> extensions to the May shading implementation; their commits are listed below.
> The resource-merging rationale was reconstructed from the initial configuration and
> confirmed by the author during this reconstruction; it was not explicit in the initial commit.

## Context

The Java and Kotlin applications need a single JAR that can be started with `java -jar`, with
a `Main-Class` manifest entry and all runtime dependencies included. Consumers should not have
to assemble a separate dependency classpath or deploy an additional library directory.

Bundling dependencies can create collisions between resources with the same path, especially
service registrations and NOTICE files. Those resources must be handled deliberately so that
the combined application retains the information it needs. Specialized parents should reuse
the packaging rather than create incompatible executable-artifact conventions.

## Decision

Package applications as executable shaded JARs containing their runtime dependencies and a
manifest entry point configured through `main.class`. Use the shaded JAR as the main Maven
artifact with the standard artifact-ID/version filename. Apply this packaging to Micronaut
without letting its Maven lifecycle extension take over packaging.

Use Shade's resource transformers to merge `META-INF/services` registrations and NOTICE
information and handle Apache license resources. Filter dependency manifests and signatures
that are not valid for the combined artifact. Class relocation is not configured and is not
the reason for selecting Shade.

## Consequences

- **Positive:** A single application artifact can be started with `java -jar` and follows
  standard Maven naming. Resource transformers preserve combined service registrations and
  handle shared metadata explicitly rather than relying on simple file aggregation.
- **Negative:** Bundled dependencies increase artifact size and require correct merging or
  preservation of service and framework metadata.
- **Risks / neutral:** An executable shaded JAR is an application artifact, not automatically
  a suitable library dependency. Shading does not by itself remove vulnerable or unused code.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Maven Shade Plugin | ✅ | Bundles runtime dependencies and provides dedicated service and NOTICE resource transformers |
| Maven JAR Plugin with `Main-Class` alone | ❌ | Makes the application JAR executable but does not bundle its runtime dependencies |
| Maven Assembly Plugin with `jar-with-dependencies` | Not selected | Provides basic fat-JAR support; resource collisions need additional handling, while Shade directly supports our required transformations |
| Application JAR plus a separate `lib/` directory | ❌ | Does not meet the single-artifact distribution goal |
| Framework-specific repackaging | Not selected | Introduces framework-specific launcher or packaging conventions instead of a shared Java/Kotlin approach |

Assembly can be extended to handle resources; the distinction is not that it is incapable,
but that Shade directly provides the transformations already used in our initial configuration.

## References

- Git `1088e95` (2026-05-12), `eff4ff8` (2026-05-17): shading and configurable entry point.
- Git `8af5cbc` (2026-09-15): shared Micronaut packaging.
- Git `25897c2`, `f8c3e3e` (2026-09-22): main artifact and standard naming.
- [Executable JARs](../../Features.md#executable-application-jars).
- [Assembly's basic fat-JAR support](https://maven.apache.org/plugins/maven-assembly-plugin/descriptor-refs.html#jar-with-dependencies).
- [Shade resource transformers](https://maven.apache.org/plugins/maven-shade-plugin/examples/resource-transformers.html).

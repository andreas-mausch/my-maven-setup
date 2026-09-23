# Design Decisions

This document records the main design decisions and trade-offs behind the project.

## Why still Maven in 2026?

For Java and Kotlin, Maven is still the most stable and well-supported build tool I know. I've looked for better
alternatives, but haven't found one yet. And I absolutely dislike Gradle.
You write a program to compile your program? That sounds like a bad concept to me.
And it shows when you try to upgrade to a newer Gradle version: Often there are
incompatibilities, you might have to rewrite a lot of your `build.gradle` and sometimes
a plugin doesn't work under the new version. I've also experienced that Gradle didn't
work with a newly released Java version and just declined to run the build at all.
This was fixed 1-3 weeks after the release, but still a blocker.

Then the Gradle Wrapper: Another flawed concept, and I think it mainly exists due to
the big incompatibility between Gradle versions. Following this concept, you
could use the same argument to have a JDK wrapper. Software should be installed
on the system by the user, in my opinion.

Then there is the Gradle Daemon, which doesn't improve the build speed at all. I always
get triggered when I see "subsequent builds will be faster". I know you can run it
without the daemon, but why is it still the default?

And for Maven: I know a Maven wrapper exists, but I don't use it and since the
`pom.xml`'s structure is fairly stable, newer Maven versions are usually able to run
older builds without any problems. I prefer to use the enforcer plugin to make sure the
user doesn't run an ancient Maven, but that's it. I like the plugin concept.

Of course, Maven is not perfect and feels old in a lot of places. And the huge XML files
are not easy to maintain. I would love YAML here, and I know there is Maven Polyglot,
but I'm not sure I want to use it yet.

## Why are the artifacts versioned independently?

`maven-build-config`, `java-parent`, `kotlin-parent`, `kotlin-micronaut-parent`, and `javacard-parent` are versioned
independently because they can evolve at different rates. All five artifacts follow Semantic Versioning.

Each consuming artifact references an explicit version of its dependency:

- `java-parent` references a specific version of `maven-build-config`.
- `kotlin-parent` references a specific version of `java-parent`.
- `kotlin-micronaut-parent` references a specific version of `kotlin-parent`.
- `javacard-parent` references a specific version of `java-parent`.

An artifact receives a new version only when that artifact changes. A release of `javacard-parent`, for example, does
not require unchanged versions of `java-parent` or `maven-build-config` to be released again.

## Why are the builds independent?

`maven-build-config`, `java-parent`, `kotlin-parent`, `kotlin-micronaut-parent`, and `javacard-parent` are built and
published independently. There is no root aggregator POM: each build resolves its dependencies from a Maven repository,
just like an external consumer.
To test current sources locally, install the artifacts in dependency order before building the examples:

```bash
mvn --file maven-build-config/pom.xml clean install
mvn --file parent-java.xml clean install
mvn --file parent-kotlin.xml clean install
mvn --file parent-kotlin-micronaut.xml clean install
mvn --file parent-javacard.xml clean install
```

The Kotlin and JavaCard parents are independent siblings and can be installed in either order after `java-parent`.
`kotlin-micronaut-parent` is installed after `kotlin-parent`. The examples explicitly disable filesystem parent lookup
with `<relativePath />`. Specialized parents retain local references to their direct parent, ensuring the parent POMs
come from the same commit when built from this repository. CI then copies all examples outside the repository and builds
them as isolated consumer projects against the independently installed artifacts.

## Why are Micronaut processor versions declared separately?

The Kotlin Micronaut parent imports the Micronaut Platform BOM for project dependencies. The KSP processors, however,
are dependencies of `ksp-maven-plugin`, not project dependencies. Maven's normal BOM import neither manages plugin
dependency versions nor exposes the BOM's properties to the importing POM. Each KSP processor therefore needs an
explicit version mirrored from the Micronaut Platform.

This is a Maven model limitation rather than a KSP-specific one. The previous kapt configuration also declared explicit
versions for annotation processors under `kotlin-maven-plugin`. Returning to kapt would consequently not eliminate the
duplicated version declarations.

Maven mixins can import both dependency management and properties from the Micronaut Platform. Once that functionality
is available in a suitable stable Maven release, the parent can use the platform's `${micronaut.*.version}` properties
instead of maintaining its own copies. Until then, the explicit processor versions must be checked whenever the
Micronaut Platform is updated.

**Path forward:** Migrate the Micronaut Platform import to a mixin after a stable Maven 4 release includes the required
mixin property support.

## Why Mongock instead of Flamingock?

Flamingock is Mongock's successor and supports Native Image, but its Maven integration uses a JSR 269 annotation
processor executed by `maven-compiler-plugin`. The
[KSP Maven plugin](https://github.com/kpavlov/ksp-maven-plugin) runs processors implemented against the KSP API and
cannot execute Flamingock's JSR 269 processor. Since javac cannot process the example's Kotlin migration classes,
adopting Flamingock would require running kapt alongside KSP solely for Flamingock, rewriting the migrations in Java, or
switching the build to Gradle. Those workarounds add disproportionate complexity to this example.

The project consequently keeps KSP and Mongock. This decision can be revisited if Flamingock adds KSP support or a clean
Maven/Kotlin integration.

**Path forward:** Adopt Flamingock once it provides a KSP processor that works with `ksp-maven-plugin`, or another clean
Maven/Kotlin integration that does not require kapt.

## Why is there no native Micronaut artifact?

Mongock does not support GraalVM Native Image. Since replacing it with Flamingock is currently not practical for this
Maven and Kotlin setup, the project cannot treat a native executable as a supported deployment artifact.

**Path forward:** Add and verify a native deployment artifact after the migration to Flamingock.

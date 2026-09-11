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

`maven-build-config`, `java-parent`, and `javacard-parent` are versioned independently because they can evolve at
different rates. All three artifacts follow Semantic Versioning.

Each consuming artifact references an explicit version of its dependency:

- `java-parent` references a specific version of `maven-build-config`.
- `javacard-parent` references a specific version of `java-parent`.

An artifact receives a new version only when that artifact changes. A release of `javacard-parent`, for example, does
not require unchanged versions of `java-parent` or `maven-build-config` to be released again.

## Why are the builds independent?

`maven-build-config`, `java-parent`, and `javacard-parent` are built and published independently. There is no root
aggregator POM: each build resolves its dependencies from a Maven repository, just like an external consumer. To test
current sources locally, install the artifacts in dependency order before building the examples:

```bash
mvn --batch-mode --no-transfer-progress --file maven-build-config/pom.xml clean install
mvn --batch-mode --no-transfer-progress --file parent-java.xml clean install
mvn --batch-mode --no-transfer-progress --file parent-javacard.xml clean install
```

The examples explicitly disable filesystem parent lookup with `<relativePath />`. `javacard-parent` retains its local
reference to `parent-java.xml`, ensuring both parent POMs come from the same commit when built from this repository. CI
then copies the examples outside the repository and builds them as isolated consumer projects against the independently
installed artifacts.

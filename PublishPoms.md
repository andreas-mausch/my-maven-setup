# Publishing Maven Artifacts

This guide covers publishing `maven-build-config`, `java-parent`, `kotlin-parent`, and `javacard-parent` to GitHub
Packages.

## Release Model

The four artifacts are versioned and released independently. Only an artifact that has changed needs a new release.
Its published POM must reference already published release versions of its dependencies.

For the initial release, publish the artifacts in this order:

1. `maven-build-config`
2. `java-parent`
3. `kotlin-parent` and `javacard-parent` in either order

Later releases only need to preserve the relevant dependency order. For example, publish a new `maven-build-config`
before a `java-parent` release that references it, and publish that `java-parent` before a `kotlin-parent` or
`javacard-parent` release that references it.

## Preparing a Release

Before creating a release tag:

1. Set the artifact's project version to the intended release version without `-SNAPSHOT`.
2. Replace all `-SNAPSHOT` references in that artifact's POM with already published release versions.
3. Build and commit the release-ready POM.
4. Create the matching artifact-specific tag on that commit.

The examples and other independently versioned artifacts do not need a version change unless they are part of the
same release.

## Release Tags

Push one of the following tag formats to trigger `.github/workflows/maven-publish.yml`:

| Artifact             | Tag format                      | Example                         |
|----------------------|---------------------------------|---------------------------------|
| `maven-build-config` | `maven-build-config-v<version>` | `maven-build-config-v1.0.0`     |
| `java-parent`        | `java-parent-v<version>`        | `java-parent-v1.0.0`            |
| `kotlin-parent`      | `kotlin-parent-v<version>`      | `kotlin-parent-v1.0.0`          |
| `javacard-parent`    | `javacard-parent-v<version>`    | `javacard-parent-v1.0.0`        |

Example:

```bash
git tag maven-build-config-v1.0.0
git push origin maven-build-config-v1.0.0
```

The workflow rejects the release if the tag version differs from the selected POM's project version or if that POM
still contains a `-SNAPSHOT` version.

## Published Artifacts

The workflow uses the normal Maven lifecycle and each project's `distributionManagement` configuration. Its Maven
settings include GitHub Packages as a dependency repository so an artifact can resolve its previously published
parent. GitHub Actions authenticates with the repository's `GITHUB_TOKEN`; no personal access token is required.

`maven-build-config` publishes both its main JAR and the attached JavaCard license metadata:

| Artifact                                 | Type         | Classifier    | Description                    |
|------------------------------------------|--------------|---------------|--------------------------------|
| `de.neonew:maven-build-config:<version>` | `jar`        |               | Shared build configuration JAR |
| `de.neonew:maven-build-config:<version>` | `properties` | `third-party` | JavaCard license metadata      |
| `de.neonew:java-parent:<version>`        | `pom`        |               | General Java parent POM        |
| `de.neonew:kotlin-parent:<version>`      | `pom`        |               | Pure Kotlin/JVM parent POM     |
| `de.neonew:javacard-parent:<version>`    | `pom`        |               | JavaCard parent POM            |

Using `mvn deploy` instead of `deploy:deploy-file` is important for `maven-build-config`: the lifecycle attaches and
deploys the classified `third-party.properties` artifact together with the main JAR.

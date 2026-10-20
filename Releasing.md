# Publishing Maven Artifacts

This guide covers publishing `maven-build-config`, `java-parent`, `kotlin-parent`, `kotlin-micronaut-parent`, and
`javacard-parent` to GitHub Packages.

## Coordinated Release

Use a coordinated release when all five artifacts advance to the same version. This is the normal release path. It
keeps the complete dependency hierarchy in one release-ready commit and validates that exact state once before any
artifact is published.

The examples below release version `1.1.0` and then start `1.2.0-SNAPSHOT` development. Replace both versions as
appropriate.

### 1. Prepare the Release

Update all project versions and internal references together:

| POM                           | Project version | Internal reference                                           |
|-------------------------------|-----------------|--------------------------------------------------------------|
| `maven-build-config/pom.xml`  | `1.1.0`         |                                                              |
| `parent-java.xml`             | `1.1.0`         | `version.maven-build-config` = `1.1.0`                       |
| `parent-kotlin.xml`           | `1.1.0`         | Parent `java-parent` = `1.1.0`                               |
| `parent-javacard.xml`         | `1.1.0`         | Parent `java-parent` = `1.1.0`                               |
| `parent-kotlin-micronaut.xml` | `1.1.0`         | Parent `kotlin-parent` = `1.1.0`                             |

The release POMs must not contain any `-SNAPSHOT` versions. The checked-in examples remain on the previous release
until publication is complete.

Verify the artifacts locally in dependency order. `install` is required for artifacts consumed by a subsequent
build:

```bash
mvn --file maven-build-config/pom.xml clean install
mvn --file parent-java.xml clean install
mvn --file parent-kotlin.xml clean install
mvn --file parent-javacard.xml clean install
mvn --file parent-kotlin-micronaut.xml clean verify
```

Commit and push all release POMs together:

```bash
git add \
  maven-build-config/pom.xml \
  parent-java.xml \
  parent-kotlin.xml \
  parent-javacard.xml \
  parent-kotlin-micronaut.xml
git commit -m "release: prepare 1.1.0"
git push origin main
```

### 2. Wait for Release CI

Wait until the release commit passes the complete CI workflow. Do not create or push release tags for an unverified
commit.

All release tags in a coordinated release must point to this same commit.

### 3. Publish the Build Configuration

`java-parent` uses `maven-build-config` as a plugin dependency, so publish the build configuration first:

```bash
git tag maven-build-config-v1.1.0
git push origin maven-build-config-v1.1.0
```

Wait until the publish workflow completes successfully before continuing.

### 4. Publish the Java Parent

```bash
git tag java-parent-v1.1.0
git push origin java-parent-v1.1.0
```

Wait until the publish workflow completes successfully before continuing.

### 5. Publish the Kotlin and JavaCard Parents

Both artifacts depend on `java-parent` but not on each other. After `java-parent` has been published, their tags may be
pushed together and their publish workflows may run in parallel:

```bash
git tag kotlin-parent-v1.1.0
git tag javacard-parent-v1.1.0
git push origin kotlin-parent-v1.1.0 javacard-parent-v1.1.0
```

Wait until both publish workflows complete successfully before continuing.

### 6. Publish the Micronaut Parent

`kotlin-micronaut-parent` depends on `kotlin-parent` and is therefore published last:

```bash
git tag kotlin-micronaut-parent-v1.1.0
git push origin kotlin-micronaut-parent-v1.1.0
```

Wait until the publish workflow completes successfully. The coordinated release is now public.

### 7. Start the Next Development Version

Update the four example POMs to use the new `1.1.0` parent releases. At the same time, advance all five maintained
artifacts and their internal references to `1.2.0-SNAPSHOT`.

Verify the maintained artifacts again in dependency order, then commit and push the complete post-release state:

```bash
git add \
  examples/java/pom.xml \
  examples/kotlin/pom.xml \
  examples/kotlin-micronaut/pom.xml \
  examples/javacard/pom.xml \
  maven-build-config/pom.xml \
  parent-java.xml \
  parent-kotlin.xml \
  parent-javacard.xml \
  parent-kotlin-micronaut.xml
git commit -m "build: start 1.2.0 development"
git push origin main
```

Wait until the complete CI workflow passes. The repository should now contain stable examples of the published
release while development continues on the next snapshot version.

## Single-Artifact Release

The five artifacts are versioned independently. Use this procedure when only one artifact changed and its downstream
artifacts do not need a new release.

### 1. Select the Artifact

Select the matching POM and artifact name:

| Artifact                  | POM path                      |
|---------------------------|-------------------------------|
| `maven-build-config`      | `maven-build-config/pom.xml`  |
| `java-parent`             | `parent-java.xml`             |
| `kotlin-parent`           | `parent-kotlin.xml`           |
| `kotlin-micronaut-parent` | `parent-kotlin-micronaut.xml` |
| `javacard-parent`         | `parent-javacard.xml`         |

For example, to release `java-parent`:

```bash
pom=parent-java.xml
artifact=java-parent
```

### 2. Prepare the Release

```bash
mvn --file "$pom" \
  versions:set \
  -DremoveSnapshot=true \
  -DprocessParent=false \
  -DgenerateBackupPoms=false

version="$(mvn --quiet \
  --file "$pom" \
  help:evaluate \
  -Dexpression=project.version \
  -DforceStdout \
  -Dstyle.color=never)"

mvn --file "$pom" clean verify
git add "$pom"
git commit -m "release: $artifact $version"
git push origin main
```

Replace any `-SNAPSHOT` references in that artifact's POM with already published release versions before committing.

### 3. Wait for CI, Tag, and Publish

Wait until the release commit passes the complete CI workflow before tagging it:

```bash
git tag "$artifact-v$version"
git push origin "$artifact-v$version"
```

Wait until the publish workflow completes successfully.

### 4. Start the Next Snapshot

```bash
mvn --file "$pom" \
  versions:set \
  -DnextSnapshot=true \
  -DnextSnapshotIndexToIncrement=2 \
  -DprocessParent=false \
  -DgenerateBackupPoms=false

version="$(mvn --quiet \
  --file "$pom" \
  help:evaluate \
  -Dexpression=project.version \
  -DforceStdout \
  -Dstyle.color=never)"

git add "$pom"
git commit -m "build: start $artifact $version"
git push origin main
```

Wait until the complete CI workflow passes.

## Release Model

Only an artifact that has changed needs a new release. Its published POM must reference already published release
versions of its dependencies.

The dependency order is:

1. `maven-build-config`
2. `java-parent`
3. `kotlin-parent` and `javacard-parent` in either order or in parallel
4. `kotlin-micronaut-parent`

`processParent=false` is important for single-artifact releases because the artifacts are versioned independently. It
prevents the Versions Plugin from changing the selected POM's parent version as part of the project version update.
Release candidates and other versions that do not follow the normal `-SNAPSHOT` flow must be set explicitly with
`-DnewVersion=<version>`.

The examples and other independently versioned artifacts do not need a version change unless they are part of the same
release. After a coordinated release, the examples are updated to consume the newly published parent versions.

## Release Tags

Pushing one of the following tag formats triggers `.github/workflows/publish.yaml`:

| Artifact                  | Tag format                              | Example                             |
|---------------------------|-----------------------------------------|-------------------------------------|
| `maven-build-config`      | `maven-build-config-v<version>`         | `maven-build-config-v1.1.0`         |
| `java-parent`             | `java-parent-v<version>`                | `java-parent-v1.1.0`                |
| `kotlin-parent`           | `kotlin-parent-v<version>`              | `kotlin-parent-v1.1.0`              |
| `kotlin-micronaut-parent` | `kotlin-micronaut-parent-v<version>`    | `kotlin-micronaut-parent-v1.1.0`    |
| `javacard-parent`         | `javacard-parent-v<version>`            | `javacard-parent-v1.1.0`            |

The workflow rejects a release if the tag version differs from the selected POM's project version or if that POM still
contains a `-SNAPSHOT` version.

## Published Artifacts

The workflow uses the normal Maven lifecycle and each project's `distributionManagement` configuration. Its Maven
settings include GitHub Packages as a dependency repository so an artifact can resolve its previously published
parent. GitHub Actions authenticates with the repository's `GITHUB_TOKEN`; no personal access token is required.

`maven-build-config` publishes both its main JAR and the attached JavaCard license metadata:

| Artifact                                      | Type         | Classifier    | Description                    |
|-----------------------------------------------|--------------|---------------|--------------------------------|
| `de.neonew:maven-build-config:<version>`      | `jar`        |               | Shared build configuration JAR |
| `de.neonew:maven-build-config:<version>`      | `properties` | `third-party` | JavaCard license metadata      |
| `de.neonew:java-parent:<version>`             | `pom`        |               | General Java parent POM        |
| `de.neonew:kotlin-parent:<version>`           | `pom`        |               | Pure Kotlin/JVM parent POM     |
| `de.neonew:kotlin-micronaut-parent:<version>` | `pom`        |               | Kotlin/Micronaut parent POM    |
| `de.neonew:javacard-parent:<version>`         | `pom`        |               | JavaCard parent POM            |

Using `mvn deploy` instead of `deploy:deploy-file` is important for `maven-build-config`: the lifecycle attaches and
deploys the classified `third-party.properties` artifact together with the main JAR.

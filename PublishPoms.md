# Publishing Parent POMs

This guide covers how to publish `parent-java.xml` and `parent-javacard.xml` to GitHub Packages.

## Prerequisites

- A GitHub Personal Access Token (PAT) with `write:packages` and `repo` scopes
- The token configured in `~/.m2/settings.xml`:

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                      http://maven.apache.org/xsd/settings-1.0.0.xsd">

  <activeProfiles>
    <activeProfile>github</activeProfile>
  </activeProfiles>

  <profiles>
    <profile>
      <id>github</id>
      <repositories>
        <repository>
          <id>github</id>
          <url>https://maven.pkg.github.com/andreas-mausch/my-maven-setup</url>
          <snapshots>
            <enabled>true</enabled>
          </snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>

  <servers>
    <server>
      <id>github</id>
      <username>YOUR_GITHUB_USERNAME</username>
      <password>YOUR_PERSONAL_ACCESS_TOKEN</password>
    </server>
  </servers>
</settings>
```

## Deploy Commands

Both parent POMs use `deploy:deploy-file` for consistency. This bypasses the Maven lifecycle entirely and simply uploads the POM file as a Maven artifact.

### parent-java.xml

```bash
mvn deploy:deploy-file \
  -DpomFile=parent-java.xml \
  -Dfile=parent-java.xml \
  -Durl=https://maven.pkg.github.com/andreas-mausch/my-maven-setup \
  -DrepositoryId=github
```

### parent-javacard.xml

```bash
mvn deploy:deploy-file \
  -DpomFile=parent-javacard.xml \
  -Dfile=parent-javacard.xml \
  -Durl=https://maven.pkg.github.com/andreas-mausch/my-maven-setup \
  -DrepositoryId=github
```

The `-DpomFile` flag tells Maven to read `groupId`, `artifactId`, `version`, and `packaging` from the POM itself.

`deploy:deploy-file` is used for both POMs instead of plain `mvn deploy` because `parent-javacard.xml` has applet-specific plugins (enforcer, build-helper, proguard, jcdk) bound to lifecycle phases that would fail without the required properties (`applet.id`, `main.class`, `java.compiler.main.path`, `javacard.sdk.path`). Using the same command for both keeps things uniform.

## Published Artifacts

After deploying, the following artifacts are available on GitHub Packages:

| Artifact                                   | Description                               |
|--------------------------------------------|-------------------------------------------|
| `de.neonew:java-parent:1.0.0-SNAPSHOT`     | General Java parent POM                   |
| `de.neonew:javacard-parent:1.0.0-SNAPSHOT` | JavaCard parent POM (extends java-parent) |

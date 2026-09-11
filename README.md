# My Maven Setup

**my-maven-setup** is my personal, opinionated Maven parent POM collection. It provides ready-to-use parent POMs for
different project types so I do not have to repeat the same plugin and dependency configuration in every project.

Currently available:

- **Java** (`parent-java.xml`): general Java project setup
- **JavaCard** (`parent-javacard.xml`): JavaCard applet build setup extending the Java parent

Planned:

- Kotlin
- Kotlin-Micronaut
- more to come

Each project type has a complete example in the `examples/` directory.

## Getting Started

- **Plain Java:** [README-java.md](README-java.md)
- **JavaCard applet:** [README-javacard.md](README-javacard.md)
- **Shared build features:** [Features.md](Features.md)
- **Design decisions:** [Decisions.md](Decisions.md)

## Available Parent POMs

The Maven configuration consists of the shared build configuration, two parent POMs, and the consumer project's POM:

- `maven-build-config/pom.xml`: packages shared formatter and license-check configuration.
- `pom.xml` in your project: project-specific settings, plugins, and dependencies.
- `parent-java.xml`: general Maven settings for Java projects; also specifies plugin versions and default configuration.
- `parent-javacard.xml`: configuration shared across all JavaCard projects.

| Parent POM            | Artifact                               | Description                                                                                   |
|-----------------------|----------------------------------------|-----------------------------------------------------------------------------------------------|
| `parent-java.xml`     | `de.neonew:java-parent:1.0.0-rc.1`     | Manages Java build, testing, quality, metadata, packaging, and maintenance plugins            |
| `parent-javacard.xml` | `de.neonew:javacard-parent:1.0.0-rc.1` | Extends the Java parent with JDK 8 compilation, ProGuard, JCDK, and jCardSim configurations   |

## Configure GitHub Packages

The parent POMs and shared configuration are published in GitHub Packages. Configure Maven to resolve them from this
repository and provide a GitHub personal access token with `read:packages` permission. For example, add this server and
profile to `~/.m2/settings.xml`:

```xml
<settings>
  <servers>
    <server>
      <id>github</id>
      <username>${env.GITHUB_ACTOR}</username>
      <password>${env.GITHUB_TOKEN}</password>
    </server>
  </servers>
  <profiles>
    <profile>
      <id>github-packages</id>
      <repositories>
        <repository>
          <id>github</id>
          <url>https://maven.pkg.github.com/andreas-mausch/my-maven-setup</url>
        </repository>
      </repositories>
    </profile>
  </profiles>
  <activeProfiles>
    <activeProfile>github-packages</activeProfile>
  </activeProfiles>
</settings>
```

Set `GITHUB_ACTOR` to your GitHub username and `GITHUB_TOKEN` to the token before running Maven. For development of the
parent artifacts themselves, install them locally in the order documented in [Decisions.md](Decisions.md#why-are-the-builds-independent).

## Requirements

- **JDK 25+** for Maven and tests
- **Maven 3.9+**
- **JDK 8 `javac`** for JavaCard applet compilation

JavaCard applet code is compiled with `-target 1.1`, which modern JDKs reject. Only the applet compilation step requires
JDK 8; Maven and the tests still run with JDK 25+.

## Disclaimer

This project was created using AI (opencode, Big Pickle, Qwen3.6).

It is one of my first experiments with coding AI agents and also a learning experiment for me.
I can recommend running Qwen3.6 locally.
I have used the exact model Qwen3.6-35B-A3B (Q4_K_M) on my gaming PC
(4070 Ti 12 GB VRAM, 64 GB DDR4) and get around 30 tokens/sec with a context length of 65536.

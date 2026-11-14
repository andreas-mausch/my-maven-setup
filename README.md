# My Maven Setup

**my-maven-setup** is my personal, opinionated Maven parent POM collection. It provides ready-to-use parent POMs for
different project types so I do not have to repeat the same plugin and dependency configuration in every project.

Currently available:

- **Java** (`parent-java.xml`): general Java project setup
- **Kotlin/JVM** (`parent-kotlin.xml`): pure Kotlin/JVM project setup extending the Java parent
- **Kotlin/Micronaut** (`parent-kotlin-micronaut.xml`): Micronaut application setup extending the Kotlin parent
- **JavaCard** (`parent-javacard.xml`): JavaCard applet build setup extending the Java parent

Each project type has a complete example in the `examples/` directory.

## Getting Started

- **Plain Java:** [README-java.md](README-java.md)
- **Pure Kotlin/JVM:** [README-kotlin.md](README-kotlin.md)
- **Kotlin/Micronaut:** [README-kotlin-micronaut.md](README-kotlin-micronaut.md)
- **JavaCard applet:** [README-javacard.md](README-javacard.md)

## Documentation

- **Shared build features:** [Features.md](Features.md)
- **Design decisions:** [Architecture Decision Records](docs/decisions/README.md)

## Available Parent POMs

The Maven configuration consists of the shared build configuration, four parent POMs, and the consumer project's POM:

- `maven-build-config/pom.xml`: packages shared formatter, license-check configuration, and report templates.
- `pom.xml` in your project: project-specific settings, plugins, and dependencies.
- `parent-java.xml`: general Maven settings for Java projects; also specifies plugin versions and default configuration.
- `parent-kotlin.xml`: pure Kotlin/JVM configuration extending `parent-java.xml`.
- `parent-kotlin-micronaut.xml`: Micronaut configuration extending `parent-kotlin.xml`.
- `parent-javacard.xml`: configuration shared across all JavaCard projects.

| Parent POM                    | Artifact                                        | Description                                                                                   |
|-------------------------------|-------------------------------------------------|-----------------------------------------------------------------------------------------------|
| `parent-java.xml`             | `de.neonew.build:java-parent:1.0.0`                    | Manages Java build, testing, quality, metadata, packaging, and maintenance plugins            |
| `parent-kotlin.xml`           | `de.neonew.build:kotlin-parent:1.0.0`                  | Extends the Java parent with pure Kotlin/JVM compilation and formatting                       |
| `parent-kotlin-micronaut.xml` | `de.neonew.build:kotlin-micronaut-parent:1.0.0`        | Adds Micronaut dependency management, processing, and application packaging                   |
| `parent-javacard.xml`         | `de.neonew.build:javacard-parent:1.0.0`                | Extends the Java parent with JDK 8 compilation, size optimization, JCDK, and jCardSim support |

All artifacts are published to Maven Central and resolve from there without additional Maven settings or credentials.

For development of the parent artifacts themselves, install them locally in the order documented in
[Development](#development).

## Development

Install the current artifacts in dependency order before testing consumers:

```bash
mvn --file maven-build-config/pom.xml clean install
mvn --file parent-java.xml clean install
mvn --file parent-kotlin.xml clean install
mvn --file parent-kotlin-micronaut.xml clean install
mvn --file parent-javacard.xml clean install
```

Kotlin and JavaCard are independent siblings after `java-parent`; Micronaut follows Kotlin.
Examples reference released parent versions and disable filesystem parent lookup. To test current
sources, use temporary consumer copies with their parent versions synchronized to the installed artifacts,
as CI does. See [ADR-0004](docs/decisions/0004-build-isolation.md) for the rationale.

## Requirements

- **JDK 25+** for Maven and tests
- **Maven 3.9.16+**
- **JDK 8 `javac`** for JavaCard applet compilation

JavaCard applet code is compiled with `-target 1.1`, which modern JDKs reject. Only the applet compilation step requires
JDK 8; Maven and the tests still run with JDK 25+.

## Disclaimer

This project was created using AI (opencode, Big Pickle, Qwen3.6).

It is one of my first experiments with coding AI agents and also a learning experiment for me.
I can recommend running Qwen3.6 locally.
I have used the exact model Qwen3.6-35B-A3B (Q4_K_M) on my gaming PC
(4070 Ti 12 GB VRAM, 64 GB DDR4) and get around 30 tokens/sec with a context length of 65536.

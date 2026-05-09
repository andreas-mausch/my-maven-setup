# Requirements

This project uses two separate Java compilers:

- **Main sources (applet code)** — compiled against Java 1.1 with a **JDK 8** `javac`, because recent JDKs (17+) reject the old `-target 1.1` option that JavaCards require. You must specify the path to your JDK 8 `javac` via `-Djava.compiler.main.path`.
- **Test sources** — compiled normally using whatever JDK is on your `$PATH` / `$JAVA_HOME` (Java 17+ recommended).

You can use any modern Java version for running tests and general development. Only the applet compilation step requires JDK 8.

> **Note:** If you increase the target version beyond 1.1, the resulting `.cap` file may not run on all JavaCards.

# Configuration

I have split the Maven configuration into three files:

- `pom.xml` for project-specific settings, plugins and dependencies.
- `parent-javacard.xml` for configuration related to all JavaCard projects.
- `parent-java.xml` for my general favorite Maven settings for Java projects.
  It also specifies the plugin versions and default configuration.

# Build

```bash
mvn clean verify -Djava.compiler.main.path=/path/to/jdk8/bin/javac
```

The `-Djava.compiler.main.path` argument is **required** — the build will fail without it. This tells the compiler which JDK 8 `javac` to use for applet code.

To avoid passing it every time, persist it in `.mvn/maven.config`:

```bash
echo '-Djava.compiler.main.path=/path/to/jdk8/bin/javac' > .mvn/maven.config
```

# Run single test

```bash
mvn test [-Dtest=TestClass#testMethod]
mvn failsafe:integration-test [-Dit.test=TestClass#testMethod]
```

# Signing

Artifacts can be signed with GPG using the `sign` profile. You must specify the key fingerprint via `-Dgpg.key`:

```bash
mvn -Psign -Dgpg.key=1234567890ABCDEF1234567890ABCDEF12345678 clean verify
```

Find your key fingerprint with `gpg --list-secret-keys`.

# Maintenance

Update dependency versions:

```bash
mvn versions:display-dependency-updates
mvn versions:display-plugin-updates
mvn versions:display-property-updates -DincludeParent
```

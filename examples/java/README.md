# Java Example

A minimal but complete Java project demonstrating every feature of the
[`de.neonew:java-parent`](../../parent-java.xml) POM.

## What it does

A small person-data library that parses `"LastName, FirstName"` strings
and reads person records from files. Nothing fancy — just enough code to
have meaningful unit tests and integration tests.

## Project structure

```
src/
├── main/java/de/neonew/person/
│   ├── Person.java                 # Person record
│   ├── PersonParser.java           # Parses "Last, First" → Person
│   └── PersonFileReader.java       # Reads persons from an InputStream
├── test/java/de/neonew/person/
│   └── PersonParserTest.java       # 11 unit tests (pure logic)
└── test-integration/
    ├── java/de/neonew/person/integration/
    │   └── PersonFileReaderTest.java   # 6 integration tests (file I/O)
    └── resources/
        └── test-people.txt             # Test data loaded via classpath
```

## Build

```bash
mvn clean verify
```

This runs everything: enforcer, compile, unit tests (surefire),
integration tests (failsafe), JaCoCo coverage, shaded JAR packaging,
and the console coverage report.

### Run only unit tests

```bash
mvn test
```

### Run only integration tests

```bash
mvn failsafe:integration-test
```

## Run the example

The built JAR is executable via `java -jar`. You need to build it first:

```bash
mvn clean package
```

Then run it with a CSV file as argument:

```bash
java -jar target/java-example-*.jar src/test-integration/resources/test-people.txt
```

Output:

```
Found 3 person(s):
  John Doe
  Jane Smith
  John von Neumann
```

The file `test-people.txt` contains sample data (including a comment line that gets skipped).

## Features demonstrated

| Feature                          | How it's used                                                                     |
|----------------------------------|-----------------------------------------------------------------------------------|
| **Enforcer**                     | Validates JDK 21+ and Maven 3.6+ on every build                                   |
| **JUnit 5 + AssertJ**            | All tests use JUnit Jupiter and AssertJ (versions managed by parent)              |
| **Surefire (unit tests)**        | `PersonParserTest` — 11 tests, excluded from failsafe                             |
| **Failsafe (integration tests)** | `PersonFileReaderTest` — 6 tests in `.integration.` package, runs during `verify` |
| **build-helper**                 | Adds `src/test-integration/java` and `src/test-integration/resources`             |
| **JaCoCo**                       | Coverage agent runs during tests; HTML report in `target/site/jacoco/`            |
| **JaCoCo console reporter**      | Coverage summary printed to console after `verify`                                |
| **git-commit-id**                | Git commit info embedded in `META-INF/git.properties` inside the JAR              |
| **Shade plugin**                 | Produces a fat JAR `target/java-example-*.jar` with `Main-Class` manifest entry   |
| **versions-maven-plugin**        | Inherited from parent — run `mvn versions:display-*` to check for updates         |

### SBOM (Software Bill of Materials)

Generates CycloneDX and SPDX JSON documents listing all dependencies:

```bash
mvn clean package -Psbom
```

Output:
- `target/bom.json` — CycloneDX
- `target/site/<name>-<version>.spdx.json` — SPDX

### License check

Fails the build if any dependency has a non-FOSS license or is missing
license metadata. Licenses are validated against the allowlist defined in
`parent-java.xml`:

```bash
mvn clean verify -Plicense-check
```

### GPG signing

Signs the JAR and POM with your GPG key. You need to specify the key
fingerprint (find it with `gpg --list-secret-keys`):

```bash
mvn -Psign -Dgpg.key=YOUR_KEY_ID clean verify
```

Signature files (`*.asc`) are produced alongside the artifacts.
Verify them with:

```bash
gpg --verify target/java-example-1.0-SNAPSHOT.jar.asc
```

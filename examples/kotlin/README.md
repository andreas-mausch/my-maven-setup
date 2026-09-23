# Kotlin Example

A pure Kotlin/JVM project demonstrating the [`de.neonew:kotlin-parent`](../../parent-kotlin.xml) POM.

## What it does

The example implements the same person-data application as the Java example. It parses `"LastName, FirstName"` values,
reads person records from files, and provides an executable shaded JAR.

## Project structure

```text
src/
|-- main/kotlin/de/neonew/person/
|   |-- Main.kt
|   |-- Person.kt
|   |-- PersonFileReader.kt
|   `-- PersonParser.kt
|-- test/kotlin/de/neonew/person/
|   `-- PersonParserTest.kt
`-- test-integration/
    |-- kotlin/de/neonew/person/integration/
    |   `-- PersonFileReaderTest.kt
    `-- resources/
        `-- test-people.txt
```

## Build

```bash
mvn clean verify
```

This compiles pure Kotlin sources for JVM 25, runs 8 unit tests and 4 integration tests, and creates an executable shaded
JAR. Optional profiles provide coverage, SBOM generation, license checks, formatting, and signing.

## Run the example

```bash
mvn clean package
java -jar target/kotlin-example-1.0.0-SNAPSHOT.jar src/test-integration/resources/test-people.txt
```

The shaded JAR is the main Maven artifact. Shade retains the unshaded JAR as
`original-kotlin-example-<version>.jar`.

Expected output:

```text
Found 4 person(s):
  John Doe
  Jane Smith
  John von Neumann
  Bob Brown
```

## Features demonstrated

| Feature                          | How it is used                                                                    |
|----------------------------------|-----------------------------------------------------------------------------------|
| Kotlin compiler                  | Compiles pure Kotlin sources to JVM 25 bytecode                                   |
| Surefire                         | Runs 8 unit tests from `src/test/kotlin`                                          |
| Failsafe                         | Runs 4 tests in the `.integration.` package during `verify`                       |
| Build Helper                     | Registers Kotlin integration-test sources and resources                           |
| JaCoCo                           | Collects JVM bytecode coverage with the `coverage` profile                        |
| git-commit-id                    | Embeds Git metadata in the JAR                                                    |
| Shade                            | Produces an executable JAR containing Kotlin stdlib and the `Main-Class` entry    |
| Spotless                         | Formats Kotlin with ktfmt when the `linting` profile is active                    |
| CycloneDX and SPDX               | Generate dependency and license metadata with the `sbom` profile                  |
| License Maven Plugin             | Checks dependency licenses with the `license-check` profile                       |
| GPG                              | Signs the JAR and POM with the `sign` profile                                     |

Kotlin generates synthetic methods and classes, so JaCoCo percentages are not directly comparable to equivalent Java
source code.

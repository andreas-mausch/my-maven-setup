# Requirements

The target Java version is set to 1.1 in the `pom.xml`.
Recent JDKs cannot build for this old target anymore,
so you need to have a JDK 8 to build this project.

Or, you can try to increase the target version, but then
I'm not sure if the built `.cap` file will still run on a JavaCard.

You might need to override the property `java.compiler.main.path`
to point to your */../jdk8/bin/javac*.

In order to still use recent Java and dependencies in the tests,
the main source is compiled with a different JDK than the tests.
They will use the Java version on your `$PATH` / `$JAVA_HOME`.

# Build

```bash
mvn clean verify
```

This will also run the tests.

Example with custom properties:

```bash
mvn -Djavacard.sdk.path='${project.basedir}/../../../external/oracle_javacard_sdks/jc305u4_kit' -Djava.compiler.main.path='/usr/lib/jvm/java-8-openjdk/bin/javac' clean verify
```

# Run single test

```bash
mvn test [-Dtest=TestClass#testMethod]
mvn failsafe:integration-test [-Dit.test=TestClass#testMethod]
```

# Maintenance

Update dependency versions:

```bash
mvn versions:display-dependency-updates
mvn versions:display-plugin-updates
mvn versions:display-property-updates -DincludeParent
```

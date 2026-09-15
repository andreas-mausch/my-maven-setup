# Kotlin/Micronaut Parent

`de.neonew:kotlin-micronaut-parent` extends the Kotlin parent with Micronaut dependency management, Kotlin annotation
processing, application packaging, and defaults for Netty applications.

## Parent

```xml
<parent>
  <groupId>de.neonew</groupId>
  <artifactId>kotlin-micronaut-parent</artifactId>
  <version>1.0.0-rc.1</version>
  <relativePath />
</parent>
```

Set the Kotlin entry point and activate the managed plugins in the consumer project:

```xml
<properties>
  <main.class>com.example.ApplicationKt</main.class>
</properties>

<build>
  <plugins>
    <plugin>
      <groupId>org.jetbrains.kotlin</groupId>
      <artifactId>kotlin-maven-plugin</artifactId>
    </plugin>
    <plugin>
      <groupId>io.micronaut.maven</groupId>
      <artifactId>micronaut-maven-plugin</artifactId>
    </plugin>
  </plugins>
</build>
```

The parent imports the Micronaut platform BOM and configures KAPT for Micronaut dependency injection, Micronaut Data,
and Micronaut Serialization. It also maps the shared `main.class` property to Micronaut's `exec.mainClass` property.

The inherited `size-optimization` profile is not supported for Micronaut applications. Micronaut owns executable-JAR
packaging, and a safe ProGuard configuration would require framework-specific keep rules and separate runtime tests.

See [`examples/kotlin-micronaut`](examples/kotlin-micronaut) for an application using HTTP, MongoDB, RabbitMQ,
Micronaut Data, JSON/BSON serialization, and Testcontainers.

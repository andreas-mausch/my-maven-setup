# Kotlin/Micronaut Parent

`de.neonew:kotlin-micronaut-parent` extends the Kotlin parent with Micronaut dependency management, Kotlin annotation
processing, application packaging, Testcontainers-backed Micronaut Test Resources, and defaults for Netty
applications.

## Parent

```xml
<parent>
  <groupId>de.neonew</groupId>
  <artifactId>kotlin-micronaut-parent</artifactId>
  <version>1.0.0-rc.1</version>
  <relativePath />
</parent>
```

Set the Kotlin entry point, the application package, and activate the managed Kotlin and Shade plugins in the consumer
project:

```xml
<properties>
  <main.class>com.example.ApplicationKt</main.class>
  <micronaut.application.package>com.example</micronaut.application.package>
</properties>

<build>
  <plugins>
    <plugin>
      <groupId>me.kpavlov.ksp.maven</groupId>
      <artifactId>ksp-maven-plugin</artifactId>
    </plugin>
    <plugin>
      <groupId>org.jetbrains.kotlin</groupId>
      <artifactId>kotlin-maven-plugin</artifactId>
    </plugin>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-shade-plugin</artifactId>
    </plugin>
  </plugins>
</build>
```

The parent imports the Micronaut platform BOM and configures KSP for Micronaut dependency injection, Micronaut Data,
and Micronaut Serialization. KSP requires Maven 3.9.16 or newer. The parent also maps the shared `main.class` property
to Micronaut's `exec.mainClass` property.

The managed Micronaut Maven plugin starts and stops Micronaut Test Resources around integration tests. Test Resources
uses Testcontainers to provision infrastructure such as MongoDB and RabbitMQ when their connection properties are
missing. The plugin runs without Micronaut's lifecycle extension and does not take over application packaging.

The parent keeps the repository's normal Shade and ProGuard packaging instead of activating Micronaut's own Maven
lifecycle extension. Consumers can therefore use the shared `size-optimization` profile. For Micronaut applications,
ProGuard performs shrinking without optimization or obfuscation and preserves generated bean definitions,
serialization metadata, application entry points, and the `META-INF/micronaut` service index.

See [`examples/kotlin-micronaut`](examples/kotlin-micronaut) for an application using HTTP, MongoDB, RabbitMQ,
Micronaut Data, JSON/BSON serialization, and Testcontainers.

# Troubleshooting

This document explains known messages emitted by tools used in the shared builds.

## CycloneDX: Unknown keyword `meta:enum` or `deprecated`

```text
[WARNING] Unknown keyword meta:enum - you should define your own Meta Schema.
[WARNING] Unknown keyword deprecated - you should define your own Meta Schema.
```

These warnings come from the CycloneDX Maven plugin validating its JSON schema against a library that does not
recognize the `meta:enum` and `deprecated` keywords. The plugin authors are aware of them, and they do not affect the
generated SBOM. See
[cyclonedx/cyclonedx-maven-plugin#564](https://github.com/CycloneDX/cyclonedx-maven-plugin/issues/564).

**Upstream owner:** CycloneDX Maven plugin. The fix was merged in
[PR #673](https://github.com/CycloneDX/cyclonedx-maven-plugin/pull/673). We are waiting for the `2.10.0` release before
updating from `2.9.3`.

## SPDX: Unknown relationship type for `provided` dependencies

```text
[WARNING] Could not determine the SPDX relationship type for dependency artifact ID <artifactId> scope provided
```

The SPDX Maven plugin does not map Maven's `provided` scope to a specific SPDX relationship type. The dependency is
still included and the generated document remains valid, but its relationship is classified as `OTHER`. This upstream
limitation affects all non-optional `provided` dependencies. See
[spdx/spdx-maven-plugin#213](https://github.com/spdx/spdx-maven-plugin/issues/213).

**Upstream owner:** SPDX Maven plugin; waiting for support for Maven's `provided` scope.

## SPDX: Ambiguous multiple Maven licenses

```text
[WARNING] The following errors were found in the SPDX file:
Relationship error: ... GPL-2.0-with-classpath-exception is deprecated. ...
```

Maven models licenses as a list without expressing whether multiple entries are alternatives (`OR`) or cumulative
requirements (`AND`). The SPDX Maven plugin maps multiple entries to `AND`, which is not necessarily correct. For
example, `jakarta.transaction-api:2.0.1` and `jakarta.annotation-api:2.1.1` list EPL 2.0 and GPL 2 with the Classpath
Exception in their Maven metadata, while their POM headers explicitly declare the alternative expression
`EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0`. The generated SPDX document instead uses
`GPL-2.0-with-classpath-exception AND EPL-2.0`.

The generated expression therefore has two separate problems. First, the plugin cannot infer the missing operator from
Maven metadata and uses `AND` where these projects declare `OR`. Second, the dependency POMs contain the Maven license
name `GPL2 w/ CPE`, not the deprecated SPDX identifier. The plugin maps that name or its Classpath license URL to
`GPL-2.0-with-classpath-exception` and then reports its own generated identifier as deprecated during semantic SPDX
validation. The current representation is `GPL-2.0-only WITH Classpath-exception-2.0`.

Dependencies with multiple licenses must be reviewed and corrected with version-specific `licenseOverwrites` where
necessary. JSON Schema validation alone does not verify these SPDX semantics.

**Upstream owner:** SPDX Maven plugin and dependency publishers; consumers must supply necessary overrides.

## SPDX: Reflective final field mutation

```text
WARNING: Final field licenses in class org.spdx.storage.listedlicense.LicenseJsonTOC has been mutated reflectively by class com.google.gson.internal.bind.ReflectiveTypeAdapterFactory$1 in unnamed module @...
WARNING: Use --enable-final-field-mutation=ALL-UNNAMED to avoid a warning
```

The SPDX Maven plugin uses Gson to mutate a `final` field through reflection. This is a JVM 21+ warning and will become
an error in a future Java release. It does not currently affect functionality.

**Upstream owner:** SPDX Maven plugin and Gson; waiting for reflection-free field handling.

## Spotless Kotlin: Terminally deprecated `sun.misc.Unsafe` method

```text
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by org.jetbrains.kotlin.com.intellij.util.containers.Unsafe (.../kotlin-compiler-embeddable-<version>.jar)
WARNING: Please consider reporting this to the maintainers of class org.jetbrains.kotlin.com.intellij.util.containers.Unsafe
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
```

Spotless' Kotlin formatter loads an embedded Kotlin compiler whose IntelliJ utility code calls a terminally deprecated
JDK method. This warning appears during `spotless:check` on JDK 25 and is independent of the similar KSP warning below.
It does not currently affect formatting, but the embedded compiler must replace the call before a future JDK removes
the method.

**Upstream owner:** Kotlin's embedded IntelliJ code used by Spotless; waiting for an updated implementation.

## KSP: Terminally deprecated `sun.misc.Unsafe` method

```text
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by ksp.com.intellij.util.containers.Unsafe (.../symbol-processing-aa-embeddable-2.3.11.jar)
WARNING: Please consider reporting this to the maintainers of class ksp.com.intellij.util.containers.Unsafe
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
```

KSP's embedded IntelliJ code calls a terminally deprecated JDK method. The warning occurs on JDK 25 and does not
currently affect code generation, but KSP must replace the call before the method is removed from a future JDK. See
[google/ksp#2753](https://github.com/google/ksp/issues/2753).

**Upstream owner:** KSP; waiting for its embedded IntelliJ code to stop using the deprecated method.

## Micronaut OpenAPI: Experimental compile-time resource contribution

```text
[INFO] [ksp:main] EXPERIMENTAL: Compile time resource contribution to the context is experimental
```

`io.micronaut.openapi:micronaut-openapi:7.1.3` emits this message when it registers the generated OpenAPI document as a
classpath resource through an API deprecated by `io.micronaut:micronaut-core-processor:5.1.15`. The API is no longer
used, but its default implementation still logs this message for every call. The OpenAPI document is generated
correctly, and the message does not indicate a build or application problem.

**Upstream owner:** Micronaut OpenAPI and Micronaut Core; waiting for the obsolete message to be removed.

## Micronaut Test Resources: Restricted native access

```text
WARNING: A restricted method in java.lang.System has been called
WARNING: java.lang.System::load has been called by com.sun.jna.Native in an unnamed module (.../micronaut-test-resources-server-<version>.jar)
WARNING: Use --enable-native-access=ALL-UNNAMED to avoid a warning for callers in this module
WARNING: Restricted methods will be blocked in a future release unless native access is enabled
```

Micronaut Test Resources uses Testcontainers, which loads native code through JNA while discovering and communicating
with Docker. JDK 25 warns because JNA is on the class path and therefore belongs to the unnamed module without native
access enabled. The warning does not currently affect test execution, but a future JDK will require the library or the
test process to enable native access explicitly.

**Upstream owner:** Micronaut Test Resources and JNA; waiting for compatible native-access handling.

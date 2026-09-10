# Plan fuer `my-maven-setup`

## 1. Examples bleiben unter `examples/`

Eigene Branches sind nicht vorgesehen. Die Beispiele bleiben eigenstaendige Maven-Projekte in:

```text
examples/java/
examples/javacard/
```

## 2. Keine Parent-Aufloesung mehr ueber lokale Dateipfade

Die Examples sollen die Parent-POMs so verwenden wie echte Nutzer:

```xml
<parent>
  <groupId>de.neonew</groupId>
  <artifactId>java-parent</artifactId>
  <version>1.0.0</version>
  <relativePath />
</parent>
```

Entsprechend gilt das auch fuer `javacard-parent`. Dessen Verweis auf `java-parent` soll ebenfalls ueber das Maven-Repository aufgeloest werden.

## 3. Zusaetzliches Config-JAR

Statische Konfigurationsdateien kommen in ein separates Maven-Artefakt, beispielsweise:

```text
de.neonew:maven-build-config:1.0.0
```

Inhalt:

```text
de/neonew/maven/version-rules.xml
de/neonew/maven/eclipse-formatter.properties
```

Das JAR wird als Plugin-Abhaengigkeit eingebunden und erscheint deshalb nicht als normale Abhaengigkeit des Nutzerprojekts.

## 4. Versions Plugin laedt Regeln aus dem Classpath

Das Versions Maven Plugin unterstuetzt dies direkt:

```xml
<properties>
  <version.rules.uri>
    classpath:///de/neonew/maven/version-rules.xml
  </version.rules.uri>
</properties>
```

```xml
<plugin>
  <groupId>org.codehaus.mojo</groupId>
  <artifactId>versions-maven-plugin</artifactId>
  <configuration>
    <rulesUri>${version.rules.uri}</rulesUri>
  </configuration>
  <dependencies>
    <dependency>
      <groupId>de.neonew</groupId>
      <artifactId>maven-build-config</artifactId>
      <version>${version.maven-build-config}</version>
    </dependency>
  </dependencies>
</plugin>
```

Nutzer koennen die Standarddatei ueber die Property durch eine eigene Datei oder URL ersetzen.

## 5. Spotless laedt die Formatter-Konfiguration ebenfalls als Ressource

Das Config-JAR wird zusaetzlich als Abhaengigkeit des Spotless Plugins eingetragen. Die Formatter-Datei soll ueber eine ueberschreibbare Property referenziert werden:

```xml
<properties>
  <spotless.eclipse.file>
    classpath:///de/neonew/maven/eclipse-formatter.properties
  </spotless.eclipse.file>
</properties>
```

Spotless benoetigt intern eine echte Datei und materialisiert eine Classpath-Ressource deshalb temporaer unter `target`. Das ist akzeptiert, weil:

- der Vorgang transparent ablaeuft;
- keine Datei dauerhaft im Checkout des Nutzers entsteht;
- kein zusaetzlicher Entpackschritt konfiguriert werden muss;
- `mvn clean` die temporaere Datei entfernt.

Vor der endgueltigen Umsetzung muss die genaue von Spotless akzeptierte Classpath-Syntax praktisch verifiziert werden.

## 6. Konfiguration bleibt ueberschreibbar

Ein Nutzer kann seine eigene Formatter-Datei angeben:

```xml
<properties>
  <spotless.eclipse.file>
    ${project.basedir}/my-eclipse-formatter.properties
  </spotless.eclipse.file>
</properties>
```

Dasselbe Prinzip gilt fuer `version.rules.uri`.

## 7. Oracle `api_classic.jar`: technische Fakten

Der bisherige Installationsbefehl erzeugt nur eine minimale POM ohne Lizenzmetadaten:

```bash
mvn install:install-file \
  -Dfile=/path/to/javacard/sdk/lib/api_classic.jar \
  -DgroupId=com.oracle.javacard \
  -DartifactId=api-classic \
  -Dversion=3.0.5 \
  -Dpackaging=jar
```

`install:install-file` bietet keinen Parameter, ueber den eine Lizenz direkt angegeben werden kann.

Fuer korrekte Lizenzmetadaten waere eine vollstaendige `api-classic-3.0.5.pom` notwendig:

```bash
mvn install:install-file \
  -Dfile=/path/to/javacard/sdk/lib/api_classic.jar \
  -DpomFile=/path/to/api-classic-3.0.5.pom
```

## 8. Oracle-POM ist noch offen

Noch nicht entschieden ist:

- ob eine vollstaendige `api-classic-3.0.5.pom` bereitgestellt wird;
- wie der Nutzer diese Datei erhaelt;
- oder ob die fehlende Lizenz weiterhin zentral ueber einen Override im Parent beziehungsweise Config-Artefakt behandelt wird.

Die Oracle-POM einfach in das Config-JAR zu legen reicht nicht: Sie waere dort eingeschlossen und koennte von `install:install-file` nicht direkt als `pomFile` verwendet werden.

## 9. CI benoetigt zwei Pruefarten

Vorgesehen ist grundsaetzlich:

- aktuelle Parent-POMs und das Config-JAR lokal installieren und anschliessend die Examples bauen;
- zusaetzlich Examples gegen tatsaechlich veroeffentlichte Artefakte bauen, um den echten Nutzerfall ohne lokale Dateipfade zu pruefen.

## Offene technische Pruefungen

- Funktioniert der gewuenschte Classpath-Pfad bei Spotless mit der konkret verwendeten Version?
- Wie wird `license-override.properties` kuenftig behandelt?
- Wird fuer Oracle eine vollstaendige POM bereitgestellt oder bleibt es beim zentralen License-Override?
- Wie werden Parent-POMs und Config-JAR gemeinsam versioniert und veroeffentlicht?

## Arbeitsanweisungen

Die Umsetzung in dieser Reihenfolge durcharbeiten:

1. Das Config-JAR `de.neonew:maven-build-config` anlegen.
2. `version-rules.xml` in das Config-JAR verschieben und das Laden ueber `classpath:///` mit dem Versions Maven Plugin testen.
3. `eclipse-formatter.properties` in das Config-JAR verschieben und das transparente Laden durch Spotless inklusive der temporaeren Datei unter `target` testen.
4. Fuer beide Ressourcen ueberschreibbare Properties in `parent-java.xml` definieren.
5. Das Config-JAR als separate Plugin-Abhaengigkeit beim Versions Maven Plugin und beim Spotless Maven Plugin eintragen.
6. Die lokale Installation und die Veroeffentlichung des Config-JARs sowie beider Parent-POMs einrichten.
7. In `parent-javacard.xml` den lokalen Verweis auf `parent-java.xml` entfernen und `<relativePath />` verwenden.
8. In beiden Example-POMs die lokalen Parent-Verweise entfernen und `<relativePath />` verwenden.
9. Beide Examples gegen die lokal installierten aktuellen Artefakte bauen und alle Profile pruefen.
10. Einen separaten CI-Test gegen die tatsaechlich veroeffentlichten Artefakte einrichten, ohne vorherige lokale Installation der Parent-POMs oder des Config-JARs.
11. Dokumentation und Beispiel-POMs auf den echten Nutzer-Workflow abstimmen.
12. Unabhaengig vom restlichen Umbau entscheiden, ob fuer `api_classic.jar` eine vollstaendige POM bereitgestellt wird oder der zentrale License-Override bestehen bleibt.

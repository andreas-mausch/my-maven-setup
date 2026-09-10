# TODO

## Umsetzung

### 1. Java-Parent

- [ ] `java-parent` lokal installieren können.
- [ ] In `examples/java/pom.xml` den lokalen Parent-Verweis durch Repository-Auflösung mit `<relativePath />` ersetzen.
- [ ] Das Java-Beispiel gegen die lokal installierten aktuellen Artefakte mit allen relevanten Profilen bauen.

### 2. JavaCard-Parent

- [ ] In `parent-javacard.xml` den lokalen Verweis auf `parent-java.xml` durch Repository-Auflösung mit
      `<relativePath />` ersetzen.
- [ ] `javacard-parent` gegen den lokal installierten `java-parent` bauen und lokal installieren können.
- [ ] In `examples/javacard/pom.xml` den lokalen Parent-Verweis durch Repository-Auflösung mit `<relativePath />`
      ersetzen.
- [ ] Das JavaCard-Beispiel gegen die lokal installierten aktuellen Artefakte mit allen relevanten Profilen bauen.

### 3. Publishing und CI

- [ ] Einen CI-Test einrichten, der zuerst Config-JAR und Parent-POMs lokal installiert und danach beide Beispiele baut.
- [ ] Einen getrennten CI-Test einrichten, der die Beispiele ohne lokale Vorinstallation gegen tatsächlich
      veröffentlichte Artefakte baut.

### 4. Dokumentation und Gesamtprüfung

- [ ] Dokumentation und Beispiel-POMs auf den neuen Nutzer-, Installations- und Publishing-Workflow abstimmen.
- [ ] Nach dem Umbau alle Profile für beide Beispiele erneut prüfen: `linting`, `sbom`, `license-check`, `coverage`,
      `sign` sowie bei JavaCard `proguard`.

## Auffälligkeiten

### Dokumentation und Hooks

- [ ] Den Pre-Commit-Hook korrigieren: Kommentar, tatsächliches Verhalten und dokumentierten Pfad `githooks` in
      Einklang bringen.
- [ ] Sicherstellen, dass der Pre-Commit-Hook dieselbe Spotless-Konfiguration wie CI verwendet und das Profil `linting`
      aktiviert.
- [ ] Entscheiden, ob der Pre-Commit-Hook nur prüfen oder automatisch formatieren soll, und die Dokumentation
      entsprechend formulieren.
- [ ] Die dokumentierte Ausgabe des Java-Beispiels an die vier Datensätze in `test-people.txt` anpassen.
- [ ] Die Anleitung für einzelne Integrationstests prüfen und statt eines unvollständigen direkten Failsafe-Aufrufs
      einen passenden Lifecycle-Aufruf dokumentieren.

### Tests und JavaCard

- [ ] Den JavaCard-Unit-Test durch einen sinnvollen Test ersetzen oder entfernen, falls er neben den Integrationstests
      keinen Mehrwert bietet.
- [ ] Entscheiden, ob JavaCard-Integrationstests die in der POM konfigurierte AID und die erzeugte CAP-Datei prüfen
      sollen.
- [ ] Die Versionsfilter in `version-rules.xml` auf zu breite und unvollständige Regexe prüfen, insbesondere Alpha- und
      `.jre`-Varianten.

### CI und Publishing

- [ ] Den in CI heruntergeladenen, aber nicht verwendeten Oracle JavaCard Simulator entweder verwenden oder aus dem
      Workflow entfernen.
- [ ] Prüfen, ob GitHub Actions reproduzierbarer per Commit-SHA statt nur per Major-Version referenziert werden sollen.
- [ ] Prüfen, ob `ubuntu-latest` durch eine feste Runner-Version ersetzt werden soll.
- [ ] Maven-Dependency-Caching und eine Aufteilung des langen CI-Jobs in unabhängige Java- und JavaCard-Jobs bewerten.

## Erledigt

- [x] 2026-09-10 Coverage und weitere optionale Funktionen in den READMEs korrekt als profilabhängig beschrieben.
- [x] 2026-09-10 Tag-basierten GitHub-Actions-Workflow für die unabhängige Veröffentlichung von Config-JAR,
      `java-parent` und `javacard-parent` eingerichtet.
- [x] 2026-09-10 Publishing auf den Maven-Lifecycle umgestellt, damit das klassifizierte Lizenzdaten-Artefakt zusammen
      mit dem Config-JAR veröffentlicht wird.
- [x] 2026-09-10 Veröffentlichungsreihenfolge dokumentiert und den bisherigen PAT-basierten Ablauf durch das
      `GITHUB_TOKEN` des Workflows ersetzt.
- [x] 2026-09-10 Temporäre Root-Symlinks für `version-rules.xml` und `eclipse-formatter.properties` entfernt und beide
      Beispiele ohne lokale Parent-Begleitdateien erfolgreich gebaut.
- [x] 2026-09-10 Oracle-Lizenzmetadaten als klassifiziertes Properties-Artefakt an `maven-build-config` angehängt.
- [x] 2026-09-10 JavaCard-Lizenzprüfung auf das zentrale Lizenzdaten-Artefakt umgestellt und ohne lokale Begleitdatei
      erfolgreich ausgeführt.
- [x] 2026-09-10 Nutzer-Override der Versionsregeln per Property mit einer eigenen Datei erfolgreich getestet.
- [x] 2026-09-10 Nutzer-Override der Formatter-Konfiguration per Property mit einer eigenen Datei erfolgreich getestet.
- [x] 2026-09-10 CI mit `--also-make` für JavaCard und unabhängigen `verify`-Aufrufen erfolgreich ausgeführt.
- [x] 2026-09-10 Applet-spezifische Plugins über das Packaging nur für JavaCard-Consumer aktiviert, sodass
      `javacard-parent` selbst im Reactor gebaut werden kann.
- [x] 2026-09-10 Maven-Projekt für das Config-JAR `de.neonew:maven-build-config` angelegt.
- [x] 2026-09-10 Unabhängige Versionierung der drei Artefakte und explizite Versionsreferenzen beschlossen.
- [x] 2026-09-10 Semantic Versioning für alle drei Artefakte festgelegt und dokumentiert.
- [x] 2026-09-10 Überschreibbare Property für den Classpath-Pfad der Versionsregeln im Java-Parent definiert.
- [x] 2026-09-10 Config-JAR als Plugin-Abhängigkeit des Versions Maven Plugins konfiguriert.
- [x] 2026-09-10 Versionsregeln mit dem Versions Maven Plugin erfolgreich aus dem Config-JAR geladen.
- [x] 2026-09-10 Config-JAR erfolgreich lokal installiert.
- [x] 2026-09-10 Unterstützten Spotless-Ressourcenpfad für die Eclipse-Formatter-Datei ermittelt.
- [x] 2026-09-10 Überschreibbare Property für den Ressourcenpfad der Eclipse-Formatter-Datei definiert.
- [x] 2026-09-10 Config-JAR als Plugin-Abhängigkeit des Spotless Maven Plugins konfiguriert.
- [x] 2026-09-10 Formatter-Konfiguration aus dem Config-JAR geladen und temporär unter `target` materialisiert.
- [x] 2026-09-10 `version-rules.xml` nach `de/neonew/maven/version-rules.xml` in das Config-JAR verschoben.
- [x] 2026-09-10 `eclipse-formatter.properties` nach `de/neonew/maven/eclipse-formatter.properties` in das Config-JAR
      verschoben.
- [x] 2026-09-10 Erzeugtes Config-JAR auf beide Ressourcen unter den vorgesehenen Classpath-Pfaden geprüft.

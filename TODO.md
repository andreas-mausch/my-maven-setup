# TODO

- [ ] Negative Consumer-Fixtures ergänzen
      Builds müssen mit der erwarteten Meldung scheitern, wenn Pflicht-Properties fehlen, eine Lizenz unzulässig ist
      oder Formatierung verletzt wird. Unterstützte Mindestversionen von Java und Maven nach Möglichkeit an ihren
      Grenzen testen, damit nicht nur der Erfolgsfall abgedeckt ist.
      - [x] Fehlendes `main.class` (Java-Parent, `size-optimization`-Profil): Enforcer meldet «You must define
        <main.class> to build an executable ProGuard JAR.» (2026-09-15)
      - [x] Fehlende JavaCard-Pflicht-Properties `applet.id`, `java.compiler.main.path` und `javacard.sdk.path`:
        jeweils die definierte Enforcer-Message (der Lauf scheitert früh, ohne JavaCard-SDK). (2026-09-15)
      - [x] Unzulässige Lizenz im `license-check`-Profil: eine Abhängigkeit außerhalb der Allowlist lässt den
        License-Check mit erwarteter Meldung scheitern. (2026-09-15)
      - [ ] Formatierungsverstoß im `linting`-Profil: absichtlich unformatierte Java- bzw. Kotlin-Datei lässt
        Spotless mit «format violations» scheitern.
      - [ ] Mindestversion Java: Java-Parent unter JDK 8 bauen → `requireJavaVersion` meldet die Versionsrange [25,).
      - [ ] Mindestversion Maven: Consumer unter Maven 3.8 bauen → `requireMavenVersion` meldet [3.9.0,), soweit eine
        ältere Maven-Version verfügbar ist.
      Jeder Negativlauf ist ein eigener CI-Schritt, der Meldungsfragment und Scheitern prüft: ein `mvn …`
      verbunden mit `| grep -q '<fragment>'` schlägt genau dann fehl, wenn der Build nicht mit der erwarteten
      Meldung endet.
## Erledigt

- [x] Git-Initialisierung der isolierten Consumer-Fixtures vereinfachen (2026-09-15)
      Java, Kotlin und JavaCard liegen in einem gemeinsamen temporären Git-Repository und werden mit einem Commit
      initialisiert. Ihre Builds bleiben in getrennten Unterverzeichnissen isoliert; die jeweiligen `.gitignore`-Dateien
      verhindern, dass Build-Ausgaben die gemeinsame Revision als geändert markieren.
- [x] Surefire-, Failsafe- und JaCoCo-Berichte auswerten (2026-09-13)
      Ein CI-Schritt prüft die Berichte strukturell statt nur auf den Maven-Exit-Code zu vertrauen: Jede Surefire- und
      Failsafe-Reportdatei enthält eine Summary-Zeile mit mindestens einem Test und ohne Failures, Errors oder
      Skipped. JaCoCo wird über Unit- und Integrationstests gemessen und im CI-Log angezeigt, ohne eine
      Mindestabdeckung als Pflicht festzulegen.
- [x] Beide SBOM-Formate validieren (2026-09-13)
      Alle erzeugten CycloneDX-1.6- und SPDX-2.3-Dateien werden mit `check-jsonschema` gegen die offiziellen JSON-Schemas
      validiert. Zusätzliche projektspezifische Prüfungen würden umfangreiche eigene Prüflogik duplizieren und sind für
      diesen Zweck nicht erforderlich.
- [x] Die vollständige erwartete Artefaktliste jedes Builds prüfen (2026-09-13)
      Die relevanten Build-Artefakte werden bereits durch Ausführung, GPG-Verifikation, Vulnerability-Scan oder
      JavaCard-Simulator geprüft. Alle Artifact-Uploads schlagen zusätzlich mit `if-no-files-found: error` fehl, wenn
      kein Pfad gefunden wird. Die ausstehenden inhaltlichen SBOM- und Report-Prüfungen werden separat behandelt.
- [x] ProGuard in `package` nach dem Shade-Plugin ausführen (2026-09-13)
      Das Size-Optimization-Profil aktiviert Shade unmittelbar vor ProGuard und bindet beide an `package`. Die
      Effective POMs von Java und Kotlin sowie echte Paket-Builds bestätigen, dass ProGuard das zuvor erzeugte
      Shaded-JAR verarbeitet.
- [x] Das geerbte Size-Optimization-Profil für das Kotlin-Beispiel testen (2026-09-13)
      Die CI baut und signiert das Kotlin-ProGuard-JAR, startet es und vergleicht seine Ausgabe vollständig. Compile-
      Abhängigkeiten gelangen durch das vorherige Shading in den ProGuard-Input, damit das optimierte JAR die benötigte
      Kotlin-Laufzeit enthält und eigenständig ausführbar ist.
- [x] Die normalen Shaded-JARs der Java- und Kotlin-Beispiele testen (2026-09-13)
      Die CI identifiziert jeweils genau ein Git-benanntes Shade-JAR, vergleicht seine Programmausgabe vollständig
      und prüft das Herausfiltern von Modul- und Signaturmetadaten. Der erfolgreiche eigenständige Start deckt zugleich
      den Manifest-Einstiegspunkt und beim Kotlin-JAR die benötigte eingebettete Laufzeit ab. Das Java-ProGuard-JAR
      wird im selben Schritt ausgeführt und seine Ausgabe ebenfalls vollständig verglichen.
      Service-Merging ist in den Beispielen nicht anwendbar, weil keine Laufzeitabhängigkeit Service-Deskriptoren
      enthält; eine künstliche Produktionsabhängigkeit wurde dafür nicht ergänzt.
- [x] GPG-Signaturen wirklich verifizieren (2026-09-13)
      Die CI listet für Java, Kotlin und JavaCard alle erwarteten JAR-, POM- und CAP-Artefakte explizit auf, prüft die
      Existenz von Artefakt und Signatur und verifiziert jede Signatur mit `gpg --verify` in einem isolierten Keyring,
      der ausschließlich den öffentlichen CI-Schlüssel enthält.

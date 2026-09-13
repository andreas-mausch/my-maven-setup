# TODO

- [ ] Das geerbte Size-Optimization-Profil für das Kotlin-Beispiel testen
      Den Build mit `-Psize-optimization` ausführen, das erzeugte `*-proguard.jar` starten und seine Ausgabe prüfen. So
      stellen wir sicher, dass Shrinking und Obfuskation mit Kotlin-Bytecode, Kotlin-Metadaten und der Kotlin-Laufzeit
      funktionieren.
- [ ] Die vollständige erwartete Artefaktliste jedes Builds prüfen
      Ein erfolgreicher Maven-Build und ein Upload mit mehreren Patterns erkennen nicht, wenn nur einzelne Dateien
      fehlen. Die Artefakte für Java, Kotlin und JavaCard explizit prüfen und beim Upload zusätzlich
      `if-no-files-found: error` setzen.
- [ ] Beide SBOM-Formate inhaltlich validieren
      CycloneDX wird aktuell nur indirekt durch Grype gelesen, SPDX nur hochgeladen. JSON und Schema sowie
      Projektkoordinaten, erwartete Abhängigkeiten und Scopes prüfen. Bei JavaCard zusätzlich sicherstellen, dass der
      Oracle-Lizenz-Override korrekt berücksichtigt wurde.
- [ ] Surefire-, Failsafe- und JaCoCo-Berichte auswerten
      Erwartete Testklassen und Testzahlen getrennt für Unit- und Integrationstests prüfen. Im JaCoCo-Bericht die
      Produktionsklassen und Beteiligung der Integrationstests prüfen sowie eine sinnvolle Mindestabdeckung festlegen,
      statt nur eine erfolgreiche Maven-Ausführung anzunehmen.
- [ ] Einen vollständigen Deployment-Test mit einem temporären Maven-Repository ergänzen
      Alle vier Projekte dorthin deployen und die Parent-POMs anschließend aus isolierten Consumer-Projekten wieder
      auflösen. Außerdem den `third-party.properties`-Classifier und das als Maven-Artefakt angehängte JavaCard-CAP
      kontrollieren.
- [ ] Generierte Metadaten und Archive gezielt untersuchen
      `META-INF/git.properties`, Implementierungs- und Spezifikationswerte sowie `Main-Class` in den Manifesten prüfen.
      Außerdem Shade-Filter, Service-Merging und die aus `1.0-SNAPSHOT` abgeleitete JavaCard-Applet-Version `1.0` im
      erzeugten Artefakt kontrollieren.
- [ ] Negative Consumer-Fixtures ergänzen
      Builds müssen mit der erwarteten Meldung scheitern, wenn Pflicht-Properties fehlen, eine Lizenz unzulässig ist
      oder Formatierung verletzt wird. Unterstützte Mindestversionen von Java und Maven nach Möglichkeit an ihren
      Grenzen testen, damit nicht nur der Erfolgsfall abgedeckt ist.
- [ ] Die dokumentierten Wartungsbefehle und den Pre-commit-Hook testen
      Alle drei `versions:display-*`-Ziele in einem isolierten Consumer ausführen, damit insbesondere die eingebetteten
      Versionsregeln geprüft werden. Den Hook einmal mit sauberer und einmal mit absichtlich fehlerhafter Formatierung
      ausführen und den Exit-Code prüfen.
- [ ] Git-Initialisierung der isolierten Consumer-Fixtures vereinfachen
      Java, Kotlin und JavaCard werden derzeit jeweils als eigenes temporäres Git-Repository initialisiert. Prüfen, ob
      ein gemeinsames temporäres Repository denselben realistischen Consumer-Test ermöglicht und drei fast identische
      Initialisierungsblöcke sowie getrennte Git-Revisionen vermeidet.

## Erledigt

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

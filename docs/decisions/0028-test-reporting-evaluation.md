---
status: proposed
date: 2026-11-12
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0028: Test reporting evaluation

> Allure is an optional experiment. Permanent adoption remains undecided; the existing report approach still applies.

## Context

The existing test, source coverage, license and vulnerability reports are small, independent,
self-contained HTML files that work well offline. A shared index provides navigation between them.
Allure offers a more attractive test presentation and historical trends, but appearance alone may
not justify another adapter, report generator and runtime.

The evaluation has two goals: improve test inspection, especially historical comparisons, and
assess whether Allure can provide one interface for all build reports. Inspection must remain
offline and independent of hosting, accounts or subscriptions. Vendor lock-in is unacceptable:
changing CI or repository providers must not remove access to readable reports and their functionality.
A hosted Allure service is not
an option. Replacing the existing reports would be welcome if Allure could cover their inspection
needs in one usable offline interface. Keep them as a comparison baseline until that capability
is demonstrated; replacement is an evaluation possibility, not an excluded outcome.

## Decision

Open. We have not decided whether to adopt Allure, replace existing reports with it, retain it
as an additional test report, or remove it after the evaluation.

## Consequences

The evaluation indicates the following benefits, costs and risks of potential adoption;
the final decision remains open.

- **Positive:**
  - Allure provides a more attractive and feature-rich interface for inspecting test results.
  - Local history enables historical comparisons and trend analysis without introducing hosting.
  - Self-contained reports keep inspection independent of GitHub/GitLab reporting interfaces
    and their subscription tiers.
  - A widely used, actively maintained reporting tool provides upstream fixes, improvements
    and features without implementing each one ourselves. If it can replace our custom reporting,
    it could reduce template and presentation maintenance while providing richer functionality.
    Those benefits require keeping Allure up to date and meeting our reporting requirements;
    retaining both solutions would not remove our existing maintenance.
- **Negative:**
  - Adoption adds test dependencies, a managed Node.js/report-generator download and ongoing
    tooling updates. Retaining our existing reports alongside Allure would duplicate test reports
    and increase artifact size and maintenance rather than replace our custom reporting.
  - Single-file output embeds the Allure frontend and is large even for small test suites.
    The inspected Micronaut CI report contains nine tests and no global attachments, yet occupies
    approximately 3.7 MB. This adds distribution and archival overhead compared with our slim reports.
  - HTML attachments provide a worse reading experience than opening our standalone reports
    through the index. In the evaluated UI, the preview is short and requires nested scrolling;
    enlarging the surrounding dialog does not give the HTML frame a useful height. The owner
    could not open the attachment directly in a new browser tab. Embedding alone therefore does
    not meet the goal of a convenient shared interface for our existing reports.
  - **Major red flag:** The tested Allure 3.19.1 awesome UI hardcodes Google Analytics enablement.
    Opening a report with network access can contact Google and transmit report metadata,
    including its UUID, Allure version and report type. We found no analytics opt-out in this UI's
    generator. This is unacceptable for permanent adoption without a reliable way to disable it;
    offline rendering alone does not resolve the privacy concern.
- **Risks / neutral:**
  - Historical trends require retaining local state and stable test identities.
  - A single HTML file can be read offline, but generation requires cached tooling and dependencies.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Keep existing reports and shared index | Current baseline | Already meets offline inspection and navigation needs |
| Optional Allure single-file report | Under evaluation | Better test presentation and potentially useful history |
| Use Allure as a unified build-report interface | Under evaluation | Native test reporting does not establish useful integration of licenses, coverage and vulnerabilities |
| Hosted Allure service | Excluded | Conflicts with offline and hosting-independent inspection |
| GitHub/GitLab provider reporting services | Excluded as the primary report interface | Useful integrated features, but inspection depends on the provider's UI and potentially paid tiers; conflicts with offline use and avoiding vendor lock-in |
| Replace existing reports with Allure | Conditional option | Welcome if it covers their inspection needs in a usable offline interface; not yet demonstrated |

Self-managed hosting does not remove coupling to a provider's reporting UI or feature tiers.
Using a provider only to store independent report files is different from relying on its UI
to render or interpret them.

## Open questions

- [ ] Is the locally verified history useful enough to justify permanent adoption?
- [ ] Is improved test inspection more than an aesthetic preference for our examples?
- [ ] Can non-test reports be integrated meaningfully, rather than merely attached or linked?
- [ ] Do HTML attachment previews preserve the search, filtering and source-coverage interactions
  of our existing reports in offline single-file mode?
- [ ] Does the benefit justify the extra dependencies, runtime downloads and duplicate reports?
- [ ] Do all four CI examples generate usable reports without disrupting existing build checks?
- [ ] Can the selected UI meet our offline and external-reference requirements without additional post-processing?

The owner's current hypothesis is that Allure does not add enough value: our shared index already
combines navigation, while Allure does not natively combine the specialized non-test reports.
This is a hypothesis to evaluate, not a concluded rejection; test history remains a potential benefit.

## Supporting research

### Evaluation setup, 2026-11-12

- Test adapter: `io.qameta.allure:allure-jupiter:3.0.0`.
- Maven plugin: `io.qameta.allure:allure-maven:3.1.0`.
- Report generator: Allure `3.19.1`, with `singleFile=true`.
- Results: `target/allure-results/`; HTML: `target/reports/allure/index.html`.
- Runtime and local history: `.allure/`, outside the directory removed by `mvn clean`.

An optional `allure` Maven profile is enabled in the four CI examples:
Java, Kotlin, Kotlin/Micronaut and JavaCard. It collects Surefire and Failsafe results and generates
a single-file HTML report during Maven's `verify` phase, after its attachments and before the
shared report index. CI uploads it alongside the existing reports and invokes report generation
separately only as a fallback after build failures or to include a later container scan.
Attachment selection uses a shared `allurerc.json` resource, extracted by the profile
and passed to the Maven plugin through `configPath`. Existing test, coverage, license and vulnerability
HTML reports become global attachments without turning them into test cases. Allure runs
after the reports to attach; later container reports require a subsequent generation.

Integration-test and coverage reports are prepared during `post-integration-test`, after test execution
has completed, regardless of whether Allure is enabled. License and dependency vulnerability reports run at
`verify`, followed by Allure and the index. This accommodates Maven's plugin execution order
without introducing another transformation plugin or a profile-dependent phase property.
The unit-test report remains at `test`. CI disables history for container-triggered regeneration
of the same test results.

Local checks cover history across successive builds and offline generation with a pre-populated runtime
cache. The experiment does not introduce persistent CI history, a hosted report service, AspectJ
instrumentation or conversions of license, coverage and vulnerability data into artificial Allure tests.

This setup provides evidence for the still-open adoption decision.

### Local results, 2026-11-12

Environment: Linux, OpenJDK 25.0.4.1, Maven 3.9.16 and Chromium 156.0.8078.79. JavaCard uses
OpenJDK 8 for applet compilation and Oracle JavaCard SDK 3.0.5u4, with tests on JDK 25.
Use isolated consumer copies with their parent versions aligned to the current sources, as
described in the repository's development instructions.

All four examples completed `mvn -Pallure clean verify allure:report` and generated a single HTML
file. JavaCard additionally needs `-Djava.compiler.main.path=<jdk8>/bin/javac` and
`-Djavacard.sdk.path=<jc305u4_kit>`. Refresh the index with
`mvn -Pallure git-commit-id:revision xml:transform@generate-report-index` to link the new file.

| Example | Reported tests | Integration tests | Result |
|---------|----------------|-------------------|--------|
| Java | 17 | 6 | All passed |
| Kotlin | 12 | 4 | All passed |
| Kotlin/Micronaut | 9 | 8 | All passed, using local Docker-backed test infrastructure |
| JavaCard | 4 | 3 | All passed |

- **History:** Two Java builds using `mvn -o -Pallure clean verify allure:report` with pre-cached
  tooling produced two distinct runs in `.allure/history/report/history.jsonl`. The first run
  survived `clean`, and both runs used the same set of test identities. The later single-file
  report embedded historical results for all 17 tests.
- **Offline inspection:** Headless Chromium opened the generated HTML through `file://` with
  HTTP/HTTPS traffic blocked by an unavailable proxy and rendered the main view with 17 passed
  tests. This is a rendering smoke test, not exhaustive browser interaction coverage.
- **Failed tests:** An intentional failure in a separate temporary Java consumer failed the
  test build as expected. A subsequent `mvn -o -Pallure allure:report` succeeded and included
  the failed test, without turning the failed test build into a successful one.
- **Existing reports:** A Java build with `allure,coverage,license-check,sbom,vulnerability-report`
  completed successfully; the shared index linked Allure alongside the existing reports.
- **Artifact size:** The inspected Micronaut CI `index.html` occupies 3,691,008 bytes for nine
  tests and zero global attachments. It rendered when copied alone into a separate directory
  and opened with networking blocked; the accompanying Maven wrapper files were not required.
- **Unified interface:** Allure documents global attachments and custom report plugins. These
  are possible extension points, not native license, code-coverage or vulnerability dashboards.
  Supported attachment types have inline previews and download links. In particular, `text/html`
  attachments are rendered in an isolated frame; the documentation says their scripts can run,
  but cannot access the parent report or load data over the network. This could provide a single
  interface for viewing our existing HTML reports without downloading each attachment first.
  Unsupported types only offer a download. This is a meaningful UX distinction from simple links,
  but does not combine report data or establish that all our interactive reports work in the frame.
  A Java evaluation build using the shared configuration embedded all five available HTML reports
  in the single Allure file, each marked `text/html`, and listed them as global attachments.
  A Kotlin build with only test reports also succeeded; missing optional report files were ignored.
  This proves attachment collection and embedding, not the behavior of our reports' interactive
  controls inside the previews, which remains to be tested.
  The owner's subsequent Chromium inspection found that the HTML preview remains very short even
  in the enlarged attachment dialog, leaving most of the dialog unused and requiring nested scrolling.
  No usable action to open the attachment in a new tab was found. This is a negative UX result for
  the selected UI, not a claim that every Allure version or attachment renderer behaves identically.
- **External reference:** The awesome UI generator in Allure 3.19.1 hardcodes analytics enablement
  with `analyticsEnable: true` and emits a script from `www.googletagmanager.com`. There is no
  opt-out in that generator. The alternative `allure2` UI generator in the same installation
  checks `ALLURE_NO_ANALYTICS=true`; that is not evidence of an opt-out for the selected awesome UI.
  The emitted analytics configuration includes `report`, `allureVersion`, `reportUuid` and
  `single_file`. Offline rendering with blocked networking works, but the default telemetry is
  a major negative finding and remains unresolved for the selected UI.

CI support is an evaluation configuration; the four local builds do not establish that the full
CI matrix, including signing and packaging checks, has already passed.

### Maven lifecycle validation, 2026-11-12

After binding Allure to `verify`, all four local examples completed `mvn -Pallure clean verify`
without an explicit `allure:report` invocation. Their indexes linked the generated Allure files.
The Java build with all report profiles generated Allure once, after integration-test, coverage,
license and dependency vulnerability HTML, then generated the index. All five HTML attachments
were embedded. A Java build without Allure also completed with integration-test and coverage
reports prepared at `post-integration-test` and the index at `verify`.
An intentionally failing Java build still failed before Allure ran; separate offline generation
then succeeded, validating the CI fallback rather than masking the test failure.

### Provider reporting alternatives, 2026-11-12

GitHub and GitLab offer integrated reporting capabilities, though not identical replacements
for every report evaluated here. GitLab imports JUnit XML into its test UI and supports test
comparisons on Free, Premium and Ultimate. Its built-in Dependency Scanning feature is documented
as Ultimate. GitHub offers dependency review with vulnerability and license information; its
dependency-review action is available for public repositories and private repositories with
GitHub Code Security or GitHub Advanced Security enabled. Test reporting in GitHub can also
be assembled through Actions checks and job summaries rather than an equivalent built-in JUnit UI.

## References

- [Allure Maven integration](https://allurereport.org/docs/integrations-maven/).
- [Allure JUnit Jupiter integration](https://allurereport.org/docs/junit-jupiter/).
- [Allure 3 configuration](https://allurereport.org/docs/v3/configure/): global attachments and plugins.
- [Allure attachments](https://allurereport.org/docs/attachments/): inline previews and HTML sandbox behavior.
- [GitLab unit test reports](https://docs.gitlab.com/ci/testing/unit_test_reports/): Free, Premium and Ultimate.
- [GitLab Dependency Scanning](https://docs.gitlab.com/user/application_security/dependency_scanning/): Ultimate.
- [GitHub dependency review](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review).
- [ADR-0008](0008-build-report-lifecycle-and-location.md): report lifecycle and location.
- [ADR-0025](0025-build-report-portability.md): offline, self-contained reporting.
- [ADR-0027](0027-code-coverage-measurement.md): dedicated coverage reporting.
- [Usage](../../Features.md#optional-allure-report-experimental).

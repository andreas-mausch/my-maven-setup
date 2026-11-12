---
status: accepted
date: 2026-11-12
deciders: [neonew]
supersedes: []
superseded-by: []
---

# 0028: Test reporting evaluation

## Context

The existing test, source coverage, license and vulnerability reports are small, independent,
self-contained HTML files that work well offline. A shared index provides navigation between them.
Allure offers a more attractive test presentation and historical trends, but appearance alone may
not justify another adapter, report generator and runtime.

The evaluation has two goals: improve test inspection, especially historical comparisons, and
assess whether Allure can provide one interface for all build reports. Inspection must remain
offline and independent of hosting, accounts or subscriptions. Vendor lock-in is unacceptable:
changing CI or repository providers must not remove access to readable reports and their functionality.
A hosted Allure service is not an option. Replacing the existing reports would be welcome if Allure could cover
their inspection needs in one usable offline interface. They served as a comparison baseline during evaluation;
replacement was an evaluation possibility, not an initially excluded outcome.

## Decision

Keep the existing standalone reports and shared index. Do not adopt Allure as a replacement or additional report.
Remove the experimental Allure integration.

## Consequences

The following benefits, drawbacks and risks concern replacing or supplementing our reports with Allure.

- **Positive:**
  - Built-in test history and historical trend comparisons add functionality that our existing
    reports do not offer. Local history works without hosting; this is a genuine functional
    benefit, not merely a difference in presentation.
  - Allure provides an attractive test presentation and tree view.
  - Allure's upstream fixes, improvements and features could reduce custom presentation
    maintenance if it replaces our reports. Retaining both would not remove our existing maintenance.
  - Single-file reports support offline inspection independent of provider reporting interfaces
    and subscription tiers, as our existing reports already do.
- **Negative:**
  - Adoption adds test dependencies, managed Node.js/report-generator downloads and ongoing Allure tooling updates.
    Retaining both solutions would duplicate test reports and maintenance rather than replace our custom reporting.
  - Allure's embedded frontend increases the distribution and archival footprint.
    The inspected Micronaut single-file report occupied approximately 3.7 MB for nine tests
    and no global attachments, compared with our slim reports.
  - The evaluated Allure 3.19.1 awesome UI does not provide the useful common interface for all build reports we wanted.
    Its HTML attachment preview was short and required nested scrolling; enlarging the dialog did not give the frame
    a useful height, and no usable open-in-new-tab action was found.
  - The tested Allure 3.19.1 awesome UI hardcodes Google Analytics enablement.
    Opening a report with network access can contact Google and transmit report metadata,
    including its UUID, Allure version and report type. No opt-out was found for this UI;
    offline rendering alone does not resolve that privacy concern. Permanent adoption without
    a reliable way to disable analytics is unacceptable.
- **Risks / neutral:**
  - Allure's local history works without hosting, but requires retaining state and stable test
    identities. Offline report generation also requires cached tooling and dependencies.

## Options considered

| Option | Verdict | Why |
|--------|---------|-----|
| Keep existing reports and shared index | ✅ | Already meets offline inspection and navigation needs |
| Optional Allure single-file report | ❌ | Appearance, tree view and history do not justify the added cost for our use case |
| Use Allure as a unified build-report interface | ❌ | The evaluated attachment UI does not provide a useful common interface for the specialized reports |
| Hosted Allure service | ❌ | Conflicts with offline and hosting-independent inspection |
| GitHub/GitLab provider reporting services | ❌ as the primary report interface | Useful integrated features, but inspection depends on the provider's UI and potentially paid tiers; conflicts with offline use and avoiding vendor lock-in |
| Replace existing reports with Allure | ❌ | Does not cover the existing reports' inspection needs in a sufficiently usable shared interface |

Self-managed hosting does not remove coupling to a provider's reporting UI or feature tiers.
Using a provider only to store independent report files is different from relying on its UI
to render or interpret them.

## Open questions

None required for this decision. Exhaustive attachment interaction tests or evaluation of alternative
Allure UIs are unnecessary given the insufficient value and additional maintenance cost.

## Supporting research

### Evaluation results, 2026-11-12

Evaluated Allure `3.19.1` with the awesome UI and single-file output, using `allure-jupiter:3.0.0`
and `allure-maven:3.1.0`.

- **Technical feasibility:** All four examples (Java, Kotlin, Kotlin/Micronaut and JavaCard)
  generated unit- and integration-test reports locally and passed CI. Generation after failed
  tests also worked without masking the build failure. Technical integration was not the reason
  for rejection.
- **History and offline use:** Repeated clean builds retained local history with stable test
  identities, and the subsequent standalone HTML embedded the previous run. Generation worked
  with cached tooling and dependencies; the HTML rendered alone with networking blocked.
  Persistent CI history and exhaustive browser interaction coverage were not evaluated.
- **Combined reporting:** Existing test, coverage, license and vulnerability HTML reports were
  successfully embedded as global attachments. However, this did not integrate their data or
  provide a convenient shared interface: the inspected previews were cramped, required nested
  scrolling and offered no usable open-in-new-tab action. Full interaction testing was unnecessary
  for the decision. Custom plugins are extension points, not demonstrated replacements for our
  specialized reports.
- **Size and privacy:** A standalone report for nine Micronaut tests occupied 3,691,008 bytes
  even without global attachments. The selected UI hardcoded `analyticsEnable: true` and emitted
  a Google Tag Manager script with report metadata; no opt-out was found for that UI.
  `ALLURE_NO_ANALYTICS=true` was recognized by the alternative allure2 renderer, not the selected
  awesome UI. Offline rendering therefore did not establish privacy when opening reports online.
- **Owner's assessment:** History is a genuine capability absent from our current reports, and
  the appearance and tree view are attractive. Nevertheless, the benefits do not justify the
  additional tooling and maintenance, especially without a useful interface for all build reports.

Provider reporting services were also considered. GitLab offers JUnit test reports on Free,
Premium and Ultimate, but its built-in Dependency Scanning is documented as Ultimate. GitHub
offers dependency review and test presentation through Actions checks and summaries; availability
of security features can depend on repository visibility and subscription. Neither provider's UI
meets our offline and vendor-independent inspection requirement as the primary report interface.

## References

- [Allure 3 configuration](https://allurereport.org/docs/v3/configure/): global attachments and plugins.
- [Allure awesome UI 3.19.1 generator source][allure-analytics]:
  line 859 hardcodes `analyticsEnable: true` when rendering the HTML template.
  [Lines 98–108][allure-analytics-template]
  conditionally include Google's `gtag.js` script based on that flag (98–99) and configure analytics
  with the report type, Allure version, report UUID and single-file flag (104–108).
- [GitLab Dependency Scanning](https://docs.gitlab.com/user/application_security/dependency_scanning/):
  GitLab's built-in dependency vulnerability scanning is available in the Ultimate tier,
  illustrating the subscription dependency of provider-integrated security reporting.
- [ADR-0025](0025-build-report-portability.md): offline, self-contained reporting.

[allure-analytics]:
  https://github.com/allure-framework/allure3/blob/v3.19.1/packages/plugin-awesome/src/generators.ts#L859
[allure-analytics-template]:
  https://github.com/allure-framework/allure3/blob/v3.19.1/packages/plugin-awesome/src/generators.ts#L98-L108

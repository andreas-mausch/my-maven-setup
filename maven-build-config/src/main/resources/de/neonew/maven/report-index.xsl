<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" html-version="5" encoding="UTF-8" indent="yes" />
  <xsl:param name="projectName" />
  <xsl:param name="projectVersion" />
  <xsl:param name="gitCommit" />
  <xsl:param name="reportsDirectory" />

  <xsl:mode name="available-reports" on-no-match="shallow-copy" />
  <xsl:template match="a" mode="available-reports">
    <xsl:variable name="directoryPath" select="replace($reportsDirectory, '\\', '/')" />
    <xsl:variable name="path" select="concat(replace($directoryPath, '/$', ''), '/', @href)" />
    <!-- Encode each segment so #, % and spaces remain part of the file path. -->
    <xsl:variable name="encodedPath"
      select="string-join(tokenize($path, '/') ! encode-for-uri(.), '/')" />
    <!-- Restore the colon in Windows drive letters, e.g. C:/ rather than C%3A/. -->
    <xsl:variable name="uriPath" select="replace($encodedPath, '^([A-Za-z])%3A/', '$1:/')" />
    <xsl:variable name="uri" select="concat(if (matches($path, '^[A-Za-z]:')) then 'file:/' else 'file:',
      $uriPath)" />
    <xsl:choose>
      <xsl:when test="unparsed-text-available($uri)">
        <xsl:copy-of select="." />
      </xsl:when>
      <xsl:otherwise>
        <span class="unavailable"><xsl:value-of select="." /><br /><small>(Not generated)</small></span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/">
    <xsl:variable name="page">
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title><xsl:value-of select="$projectName" />: Build Reports</title>
        <style>
          :root { color-scheme: light dark; --bg: Canvas; --ink: CanvasText; --muted: #777;
            --rule: #8888; --accent: #1565c0; font-family: system-ui, sans-serif; line-height: 1.5; }
          @media (prefers-color-scheme: dark) { :root { --accent: #74c0fc; } }
          body { margin: 0 auto; max-width: 90rem; padding: 1rem; background: var(--bg); color: var(--ink); }
          h1 { margin-bottom: .25rem; }
          .metadata { color: var(--muted); margin: 0 0 1.5rem; overflow-wrap: anywhere; }
          .metadata span + span::before { content: " · "; }
          table { width: 100%; border-collapse: collapse; }
          th, td { text-align: left; vertical-align: top; padding: .5rem; border-bottom: 1px solid var(--rule); overflow-wrap: anywhere; }
          tbody tr:hover { background: #8881; }
          a { color: var(--accent); }
          .unavailable { color: var(--muted); }
          code { font-size: .9em; }
          @media (min-width: 701px) { body { padding: 2rem; } }
        </style>
      </head>
      <body>
        <h1>Build Reports</h1>
        <p class="metadata">
          <span><xsl:value-of select="$projectName" /></span>
          <xsl:if test="starts-with($gitCommit, 'git:') and not(contains($gitCommit, '${')) and substring-after($gitCommit, 'git:') != ''">
            <span><xsl:value-of select="substring-after($gitCommit, 'git:')" /></span>
          </xsl:if>
          <span>Generated <xsl:value-of
            select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01] [H01]:[m01]:[s01] [ZN]',
              'en', (), 'Europe/Berlin')" /></span>
          <span><xsl:value-of select="concat(system-property('xsl:product-name'), ' ', system-property('xsl:product-version'))" /></span>
        </p>
        <table>
          <thead><tr><th scope="col">Report</th><th scope="col">Contents</th><th scope="col">Required profile / step</th></tr></thead>
          <tbody>
            <tr><td><a href="tests-unit.html">Unit tests</a></td><td>Surefire test results</td><td>Default, <code>test</code></td></tr>
            <tr><td><a href="tests-integration.html">Integration tests</a></td><td>Failsafe test results</td><td>Default, <code>verify</code>; requires integration tests</td></tr>
            <tr><td><a href="coverage.html">Coverage overview</a></td><td>Coverage by source file</td><td><code>coverage</code></td></tr>
            <tr><td><a href="coverage/jacoco.csv">JaCoCo CSV</a> / <a href="coverage/jacoco.xml">XML</a></td><td>Machine-readable coverage data</td><td><code>coverage</code></td></tr>
            <tr><td><a href="dependency-licenses.html">Dependency licenses</a></td><td>Dependencies and their licenses</td><td><code>license-check</code></td></tr>
            <tr><td><a href="THIRD-PARTY.txt">Third-party notices</a></td><td>Plain-text license list</td><td><code>license-check</code></td></tr>
            <tr><td><a href="vulnerabilities-dependencies.html">Dependency vulnerabilities</a></td><td>Grype dependency scan</td><td><code>vulnerability-report</code></td></tr>
            <tr><td><a href="vulnerabilities-container.html">Container vulnerabilities</a></td><td>Grype container scan</td><td><code>vulnerability-report</code> and container scan step</td></tr>
          </tbody>
        </table>
      </body>
    </html>
    </xsl:variable>
    <xsl:apply-templates select="$page" mode="available-reports" />
  </xsl:template>
</xsl:stylesheet>

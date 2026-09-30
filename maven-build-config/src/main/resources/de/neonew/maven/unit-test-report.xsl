<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:err="http://www.w3.org/2005/xqt-errors"
  exclude-result-prefixes="xs err">
  <xsl:output method="html" encoding="UTF-8" indent="yes" />

  <xsl:param name="projectName" />
  <xsl:param name="reportsDirectory" />
  <xsl:param name="surefireVersion" />

  <xsl:template match="/">
    <xsl:variable name="directoryUri"
      select="concat(if (matches($reportsDirectory, '^[A-Za-z]:')) then 'file:/' else 'file:',
        iri-to-uri(replace($reportsDirectory, '\\', '/')))" />
    <xsl:variable name="suites" as="element(testsuite)*">
      <xsl:try>
        <xsl:sequence
          select="collection(concat($directoryUri, '?select=TEST-*.xml;recurse=no'))/testsuite" />
        <xsl:catch errors="err:FODC0002">
          <xsl:if test="not(contains($err:description, 'does not exist'))">
            <xsl:sequence select="error($err:code, $err:description, $err:value)" />
          </xsl:if>
        </xsl:catch>
      </xsl:try>
    </xsl:variable>
    <xsl:variable name="tests" select="sum($suites/@tests)" />
    <xsl:variable name="commit"
      select="$suites[1]/properties/property[@name = 'git.commit.id.describe']/@value" />
    <xsl:variable name="failures" select="sum($suites/@failures)" />
    <xsl:variable name="errors" select="sum($suites/@errors)" />
    <xsl:variable name="skipped" select="sum($suites/@skipped)" />
    <xsl:variable name="duration" select="sum($suites/@time)" />
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Unit Tests</title>
        <style>
          :root { color-scheme: light dark; font-family: system-ui, sans-serif; line-height: 1.5; }
          body { margin: 0 auto; max-width: 90rem; padding: 2rem; }
          h1 { margin-bottom: 0.25rem; }
          .metadata { color: #777; margin: 0 0 1.5rem; }
          .metadata span + span::before { content: " · "; }
          .summary { display: grid; gap: 0.75rem; grid-template-columns: repeat(auto-fit, minmax(8rem, 1fr)); margin: 1.5rem 0; }
          .metric { border: 1px solid #8888; border-radius: 0.4rem; padding: 0.75rem; }
          .metric strong { display: block; font-size: 1.5rem; }
          .search { margin: 1rem 0; }
          .search label { display: block; font-weight: 600; margin-bottom: 0.25rem; }
          .search input { box-sizing: border-box; font: inherit; max-width: 30rem; padding: 0.5rem; width: 100%; }
          .table-container { overflow-x: auto; }
          table { border-collapse: collapse; width: 100%; }
          th, td { border-bottom: 1px solid #8888; padding: 0.5rem; text-align: left; vertical-align: top; }
          th { white-space: nowrap; }
          tbody tr:hover { background: #8881; }
          .passed { color: #16803a; }
          .failed, .error { color: #c62828; font-weight: 600; }
          .skipped { color: #8a6500; }
          details { margin-top: 0.4rem; }
          pre { overflow-x: auto; white-space: pre-wrap; }
        </style>
      </head>
      <body>
        <main>
          <h1>Unit Tests</h1>
          <p class="metadata">
            <span><xsl:value-of select="$projectName" /></span>
            <xsl:if test="$commit"><span><xsl:value-of select="$commit" /></span></xsl:if>
            <span>Generated <xsl:value-of
              select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01] [H01]:[m01]:[s01] [ZN]',
                'en', (), 'Europe/Berlin')" /></span>
            <span><xsl:value-of select="concat(system-property('xsl:product-name'), ' ',
              system-property('xsl:product-version'), ' from Maven Surefire ', $surefireVersion)" /></span>
          </p>
          <section class="summary" aria-label="Test summary">
            <div class="metric"><strong><xsl:value-of select="$tests" /></strong>Tests</div>
            <div class="metric"><strong><xsl:value-of select="$failures" /></strong>Failures</div>
            <div class="metric"><strong><xsl:value-of select="$errors" /></strong>Errors</div>
            <div class="metric"><strong><xsl:value-of select="$skipped" /></strong>Skipped</div>
            <div class="metric"><strong><xsl:value-of select="format-number($duration, '0.000')" /> s</strong>Duration</div>
          </section>
          <div class="search" hidden="hidden">
            <label for="test-search">Search tests</label>
            <input id="test-search" type="search" placeholder="Class, test, status, or output" />
          </div>
          <div class="table-container">
            <table>
              <thead>
                <tr><th scope="col">Class</th><th scope="col">Test</th><th scope="col">Status</th><th scope="col">Duration</th></tr>
              </thead>
              <tbody>
                <xsl:for-each select="$suites/testcase">
                  <xsl:sort select="@classname" />
                  <xsl:sort select="@name" />
                  <tr>
                    <td><code><xsl:value-of select="@classname" /></code></td>
                    <td>
                      <xsl:value-of select="@name" />
                      <xsl:if test="failure or error">
                        <details>
                          <summary>Details</summary>
                          <pre><xsl:value-of select="failure | error" /></pre>
                        </details>
                      </xsl:if>
                      <xsl:if test="system-out">
                        <details>
                          <summary>Standard output</summary>
                          <pre><xsl:value-of select="system-out" /></pre>
                        </details>
                      </xsl:if>
                      <xsl:if test="system-err">
                        <details>
                          <summary>Standard error</summary>
                          <pre><xsl:value-of select="system-err" /></pre>
                        </details>
                      </xsl:if>
                    </td>
                    <td>
                      <xsl:choose>
                        <xsl:when test="error"><span class="error">Error</span></xsl:when>
                        <xsl:when test="failure"><span class="failed">Failed</span></xsl:when>
                        <xsl:when test="skipped"><span class="skipped">Skipped</span></xsl:when>
                        <xsl:otherwise><span class="passed">Passed</span></xsl:otherwise>
                      </xsl:choose>
                    </td>
                    <td><xsl:value-of select="format-number(@time, '0.000')" /> s</td>
                  </tr>
                </xsl:for-each>
              </tbody>
            </table>
          </div>
        </main>
        <script>
          const search = document.querySelector('.search');
          const input = document.querySelector('#test-search');
          const rows = document.querySelectorAll('tbody tr');

          search.hidden = false;
          input.addEventListener('input', () =&gt; {
            const query = input.value.toLocaleLowerCase();
            rows.forEach((row) =&gt; {
              row.hidden = !row.textContent.toLocaleLowerCase().includes(query);
            });
          });
        </script>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>

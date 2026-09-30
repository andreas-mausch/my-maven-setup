<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:err="http://www.w3.org/2005/xqt-errors"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xmlns:local="urn:de.neonew.maven.test-report"
  exclude-result-prefixes="xs err fn local">
  <xsl:output method="html" encoding="UTF-8" indent="yes" />

  <xsl:param name="projectName" />
  <xsl:param name="reportTitle" />
  <xsl:param name="reportsDirectory" />
  <xsl:param name="testTool" />
  <xsl:param name="testToolVersion" />

  <xsl:function name="local:ansi-color-class" as="xs:string">
    <xsl:param name="code" as="xs:string" />
    <xsl:variable name="codes" select="('30', '31', '32', '33', '34', '35', '36', '37',
      '90', '91', '92', '93', '94', '95', '96', '97')" />
    <xsl:variable name="names" select="('black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white',
      'bright-black', 'bright-red', 'bright-green', 'bright-yellow', 'bright-blue', 'bright-magenta',
      'bright-cyan', 'bright-white')" />
    <xsl:sequence select="concat('ansi-color-', $code, '-', $names[index-of($codes, $code)])" />
  </xsl:function>

  <xsl:function name="local:update-ansi-classes" as="xs:string*">
    <xsl:param name="classes" as="xs:string*" />
    <xsl:param name="codes" as="xs:string*" />
    <xsl:choose>
      <xsl:when test="empty($codes)">
        <xsl:sequence select="$classes" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="code" select="$codes[1]" />
        <xsl:variable name="remaining" select="$codes[position() gt 1]" />
        <xsl:variable name="updated" as="xs:string*">
          <xsl:choose>
            <xsl:when test="$code = ('', '0')" />
            <xsl:when test="$code = '1'">
              <xsl:sequence select="distinct-values(($classes, 'ansi-bold'))" />
            </xsl:when>
            <xsl:when test="$code = '22'">
              <xsl:sequence select="$classes[. ne 'ansi-bold']" />
            </xsl:when>
            <xsl:when test="$code = '39'">
              <xsl:sequence select="$classes[not(starts-with(., 'ansi-color-'))]" />
            </xsl:when>
            <xsl:when test="$code = ('30', '31', '32', '33', '34', '35', '36', '37',
                '90', '91', '92', '93', '94', '95', '96', '97')">
              <xsl:sequence select="($classes[not(starts-with(., 'ansi-color-'))],
                local:ansi-color-class($code))" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$classes" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="local:update-ansi-classes($updated, $remaining)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template name="render-ansi">
    <xsl:param name="text" as="xs:string?" />
    <xsl:variable name="parts"
      select="analyze-string(string($text), '&amp;amp#27;\[([0-9;]*)m')/*" />
    <xsl:iterate select="$parts">
      <xsl:param name="classes" as="xs:string*" select="()" />
      <xsl:choose>
        <xsl:when test="self::fn:match">
          <xsl:next-iteration>
            <xsl:with-param name="classes"
              select="local:update-ansi-classes($classes, tokenize(string(fn:group), ';'))" />
          </xsl:next-iteration>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="exists($classes)">
              <span class="{string-join($classes, ' ')}"><xsl:value-of select="." /></span>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="." /></xsl:otherwise>
          </xsl:choose>
          <xsl:next-iteration>
            <xsl:with-param name="classes" select="$classes" />
          </xsl:next-iteration>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:iterate>
  </xsl:template>

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
        <title><xsl:value-of select="$reportTitle" /></title>
        <style>
          :root { color-scheme: light dark; font-family: system-ui, sans-serif; line-height: 1.5; }
          body { margin: 0 auto; max-width: 90rem; padding: 1rem; }
          h1 { margin-bottom: 0.25rem; }
          .metadata { color: #777; margin: 0 0 1.5rem; }
          .metadata span + span::before { content: " · "; }
          .summary { display: grid; gap: 0.75rem; grid-template-columns: repeat(auto-fit, minmax(8rem, 1fr)); margin: 1.5rem 0; }
          .metric { border: 1px solid #8888; border-radius: 0.4rem; padding: 0.75rem; }
          .metric strong { display: block; font-size: 1.5rem; }
          .search { margin: 1rem 0; }
          .search label { display: block; font-weight: 600; margin-bottom: 0.25rem; }
          .search input { box-sizing: border-box; font: inherit; max-width: 30rem; padding: 0.5rem; width: 100%; }
          .table-container { overflow: visible; }
          table { border-collapse: collapse; width: 100%; }
          table, tbody, tr, td { display: block; }
          thead { display: none; }
          tbody tr { border: 1px solid #8888; border-radius: 0.4rem; margin-bottom: 1rem; padding: 0.5rem; }
          th, td { text-align: left; vertical-align: top; }
          th { white-space: nowrap; }
          td { overflow-wrap: anywhere; padding: 0.35rem; }
          td::before { content: attr(data-label); display: block; font-weight: 600; margin-bottom: 0.15rem; }
          tbody tr:hover { background: #8881; }
          .passed { color: #16803a; }
          .failed, .error { color: #c62828; font-weight: 600; }
          .skipped { color: #8a6500; }
          details { margin-top: 0.4rem; }
          pre { font-size: 0.8rem; overflow-x: auto; overflow-wrap: anywhere; white-space: pre-wrap; }
          .ansi-bold { font-weight: 700; }
          .ansi-color-30-black { color: #555; }
          .ansi-color-31-red { color: #c62828; }
          .ansi-color-32-green { color: #16803a; }
          .ansi-color-33-yellow { color: #8a6500; }
          .ansi-color-34-blue { color: #1565c0; }
          .ansi-color-35-magenta { color: #9c27b0; }
          .ansi-color-36-cyan { color: #00838f; }
          .ansi-color-37-white { color: #777; }
          .ansi-color-90-bright-black { color: #777; }
          .ansi-color-91-bright-red { color: #ef5350; }
          .ansi-color-92-bright-green { color: #43a047; }
          .ansi-color-93-bright-yellow { color: #f9a825; }
          .ansi-color-94-bright-blue { color: #42a5f5; }
          .ansi-color-95-bright-magenta { color: #ab47bc; }
          .ansi-color-96-bright-cyan { color: #26c6da; }
          .ansi-color-97-bright-white { color: #aaa; }
          @media (prefers-color-scheme: dark) {
            .ansi-color-30-black { color: #adb5bd; }
            .ansi-color-31-red { color: #ff6b6b; }
            .ansi-color-32-green { color: #69db7c; }
            .ansi-color-33-yellow { color: #ffd43b; }
            .ansi-color-34-blue { color: #74c0fc; }
            .ansi-color-35-magenta { color: #da77f2; }
            .ansi-color-36-cyan { color: #66d9e8; }
            .ansi-color-37-white { color: #dee2e6; }
            .ansi-color-90-bright-black { color: #ced4da; }
            .ansi-color-91-bright-red { color: #ff8787; }
            .ansi-color-92-bright-green { color: #8ce99a; }
            .ansi-color-93-bright-yellow { color: #ffe066; }
            .ansi-color-94-bright-blue { color: #a5d8ff; }
            .ansi-color-95-bright-magenta { color: #e599f7; }
            .ansi-color-96-bright-cyan { color: #99e9f2; }
            .ansi-color-97-bright-white { color: #f8f9fa; }
          }
          @media (min-width: 701px) {
            body { padding: 2rem; }
            .table-container { overflow-x: auto; }
            table { display: table; }
            thead { display: table-header-group; }
            tbody { display: table-row-group; }
            tr { display: table-row; }
            tbody tr { border: 0; margin: 0; padding: 0; }
            th, td { border-bottom: 1px solid #8888; padding: 0.5rem; }
            td { display: table-cell; overflow-wrap: normal; }
            td::before { display: none; }
            pre { font-size: inherit; overflow-wrap: normal; }
          }
        </style>
      </head>
      <body>
        <main>
          <h1><xsl:value-of select="$reportTitle" /></h1>
          <p class="metadata">
            <span><xsl:value-of select="$projectName" /></span>
            <xsl:if test="$commit"><span><xsl:value-of select="$commit" /></span></xsl:if>
            <span>Generated <xsl:value-of
              select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01] [H01]:[m01]:[s01] [ZN]',
                'en', (), 'Europe/Berlin')" /></span>
            <span><xsl:value-of select="concat(system-property('xsl:product-name'), ' ',
              system-property('xsl:product-version'), ' from ', $testTool, ' ', $testToolVersion)" /></span>
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
                    <td data-label="Class"><code><xsl:value-of select="@classname" /></code></td>
                    <td data-label="Test">
                      <xsl:value-of select="@name" />
                      <xsl:if test="failure or error">
                        <details>
                          <summary>Details</summary>
                          <pre><xsl:call-template name="render-ansi">
                            <xsl:with-param name="text" select="failure | error" />
                          </xsl:call-template></pre>
                        </details>
                      </xsl:if>
                      <xsl:if test="system-out">
                        <details>
                          <summary>Standard output</summary>
                          <pre><xsl:call-template name="render-ansi">
                            <xsl:with-param name="text" select="system-out" />
                          </xsl:call-template></pre>
                        </details>
                      </xsl:if>
                      <xsl:if test="system-err">
                        <details>
                          <summary>Standard error</summary>
                          <pre><xsl:call-template name="render-ansi">
                            <xsl:with-param name="text" select="system-err" />
                          </xsl:call-template></pre>
                        </details>
                      </xsl:if>
                    </td>
                    <td data-label="Status">
                      <xsl:choose>
                        <xsl:when test="error"><span class="error">Error</span></xsl:when>
                        <xsl:when test="failure"><span class="failed">Failed</span></xsl:when>
                        <xsl:when test="skipped"><span class="skipped">Skipped</span></xsl:when>
                        <xsl:otherwise><span class="passed">Passed</span></xsl:otherwise>
                      </xsl:choose>
                    </td>
                    <td data-label="Duration"><xsl:value-of select="format-number(@time, '0.000')" /> s</td>
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

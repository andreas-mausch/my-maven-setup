<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  exclude-result-prefixes="xs map">
  <xsl:output method="html" encoding="UTF-8" indent="yes" />
  <xsl:param name="projectName" as="xs:string" select="''" />
  <xsl:param name="commit" as="xs:string" select="''" />
  <xsl:param name="coverageToolVersion" as="xs:string" select="''" />
  <xsl:param name="sourceRoots" as="xs:string" select="'roots=[]'" />

  <xsl:template name="counters">
    <xsl:param name="counters" as="element(counter)*" />
    <xsl:for-each select="('LINE', 'BRANCH', 'METHOD')">
      <xsl:variable name="type" select="." />
      <xsl:variable name="covered" select="sum($counters[@type = $type]/@covered)" />
      <xsl:variable name="total" select="$covered + sum($counters[@type = $type]/@missed)" />
      <td data-label="{if ($type = 'LINE') then 'Lines' else if ($type = 'BRANCH') then 'Branches' else 'Methods'}">
        <xsl:choose>
          <xsl:when test="$total = 0">N/A</xsl:when>
          <xsl:otherwise><xsl:value-of select="concat(format-number($covered div $total, '0.0%'),
            ' (', $covered, '/', $total, ')')" /></xsl:otherwise>
        </xsl:choose>
      </td>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="/report">
    <xsl:variable name="resolvedCommit" select="normalize-space(replace($commit, '^commit=', ''))" />
    <xsl:variable name="roots" as="xs:string*" select="
      if (matches($sourceRoots, '^roots=\[[\s\S]*\]$'))
      then tokenize(replace($sourceRoots, '^roots=\[([\s\S]*)\]$', '$1'), ',')
        ! replace(., '^\s+|\s+$', '')[. != '']
      else error(QName('', 'INVALID_SOURCE_ROOTS'), 'Expected roots=[...]')" />
    <xsl:variable name="files" as="element(sourcefile)*">
      <xsl:perform-sort select="package/sourcefile">
        <xsl:sort select="concat(../@name, '/', @name)" />
      </xsl:perform-sort>
    </xsl:variable>
    <xsl:variable name="data" as="map(*)*">
      <xsl:for-each select="$files">
        <xsl:variable name="path" select="string-join((../@name[. != ''], @name), '/')" />
        <xsl:variable name="uris" select="for $root in $roots
          return resolve-uri(string-join(tokenize($path, '/') ! encode-for-uri(.), '/'),
            concat(if (matches($root, '^[A-Za-z]:')) then 'file:/' else 'file:',
              replace(string-join(tokenize(replace(replace($root, '\\', '/'), '/+$', ''), '/') ! encode-for-uri(.), '/'),
                '^([A-Za-z])%3A/', '$1:/'), '/'))" />
        <xsl:variable name="uri" select="$uris[unparsed-text-available(., 'UTF-8')][1]" />
        <xsl:sequence select="map {
          'path': $path,
          'source': if (exists($uri)) then unparsed-text($uri, 'UTF-8') else (),
          'lines': map:merge(for $line in line return map:entry(string($line/@nr),
            array { for $attribute in ($line/@mi, $line/@ci, $line/@mb, $line/@cb) return xs:integer($attribute) }))
        }" />
      </xsl:for-each>
    </xsl:variable>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Source Coverage</title>
        <style><![CDATA[
          :root { color-scheme: light dark; --bg:Canvas; --paper:Canvas; --ink:CanvasText; --muted:#777;
            --rule:#8888; --accent:#1565c0; --covered:#16803a11; --partial:#8a650011; --missed:#c6282811;
            --passed:#16803a; --skipped:#8a6500; --failed:#c62828;
            font-family:system-ui,sans-serif; line-height:1.5; }
          @media(prefers-color-scheme:dark) { :root { --accent:#74c0fc;
            --covered:#69db7c11; --partial:#ffd43b11; --missed:#ff6b6b11;
            --passed:#69db7c; --skipped:#ffd43b; --failed:#ff6b6b; } }
          * { box-sizing:border-box; } [hidden] { display:none!important; }
          body { margin:0 auto; max-width:90rem; padding:1rem; background:var(--bg); color:var(--ink); }
          h1 { margin-bottom:.25rem; } h2 { font-size:1.15rem; overflow-wrap:anywhere; }
          .muted { color:var(--muted); }
          .metadata { color:var(--muted); margin:0 0 1.5rem; overflow-wrap:anywhere; }
          .metadata span + span::before { content:" · "; }
          .summary { display:grid; gap:.75rem; grid-template-columns:repeat(auto-fit,minmax(8rem,1fr)); margin:1.5rem 0; }
          .summary > * { border:1px solid var(--rule); border-radius:.4rem; padding:.75rem; }
          .summary strong { display:block; font-size:1.5rem; }
          .table-container { overflow:auto; }
          table { border-collapse:collapse; width:100%; }
          th,td { padding:.5rem; text-align:left; vertical-align:top; border-bottom:1px solid var(--rule); }
          th { white-space:nowrap; } td:not(:first-child) { white-space:nowrap; font-variant-numeric:tabular-nums; }
          tfoot { background:var(--bg); font-weight:600; } tbody tr:hover { background:#8881; }
          button,input { font:inherit; } button { cursor:pointer; } a { color:var(--accent); }
          .file { border:0; background:none; color:var(--accent); padding:0; text-align:left;
            font-family:ui-monospace,monospace; overflow-wrap:anywhere; }
          :focus-visible { outline:3px solid var(--accent); outline-offset:3px; }
          .toolbar { margin:1rem 0; }
          label { display:block; font-weight:600; margin-bottom:.25rem; }
          input { width:100%; max-width:30rem; background:var(--paper); color:var(--ink); border:1px solid var(--rule); padding:.5rem; }
          .legend { display:flex; flex-wrap:wrap; gap:1rem; margin:1rem 0; font-size:.8rem; }
          .legend span { padding:.2rem .5rem; border-left:3px solid var(--muted); }
          .covered { background:var(--covered); } .partial { background:var(--partial); } .missed { background:var(--missed); }
          .back { background:var(--paper); color:var(--accent); border:1px solid var(--rule); padding:.5rem .8rem; }
          .code { overflow:auto; background:var(--paper); border:1px solid var(--rule); tab-size:4; }
          .code-line { display:flex; min-width:max-content; font: .8125rem/1.75 ui-monospace,SFMono-Regular,Consolas,monospace; }
          .number { position:sticky; left:0; flex:none; width:5rem; text-align:right; padding:0 .75rem;
            background:var(--paper); color:var(--muted); border-right:3px solid var(--rule); user-select:none; }
          .covered .number, .legend .covered { border-color:var(--passed); }
          .partial .number, .legend .partial { border-color:var(--skipped); }
          .missed .number, .legend .missed { border-color:var(--failed); }
          .text { white-space:pre; padding:0 1rem; }
          #empty { padding:2rem; text-align:center; } noscript { color:var(--muted); }
          @media(min-width:701px) { body { padding:2rem; } }
          @media(max-width:700px) {
            table,tbody,tr,td { display:block; } thead { display:none; }
            tbody tr { border:1px solid var(--rule); border-radius:.4rem; margin-bottom:1rem; padding:.5rem; }
            th,td { border:0; padding:.35rem; } td { overflow-wrap:anywhere; }
            td::before { content:attr(data-label); display:block; font-weight:600; margin-bottom:.15rem; }
            tfoot { display:block; } tfoot tr { border:1px solid var(--rule); border-radius:.4rem; padding:.5rem; }
            .number { width:3.5rem; } }
        ]]></style>
      </head>
      <body>
        <main>
          <header id="report-header">
            <h1>Source Coverage</h1>
            <p class="metadata">
              <span><xsl:value-of select="$projectName" /></span>
              <xsl:if test="$resolvedCommit != '' and not(starts-with($resolvedCommit, '${'))">
                <span><xsl:value-of select="$resolvedCommit" /></span>
              </xsl:if>
              <span>Generated <xsl:value-of
                select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01] [H01]:[m01]:[s01] [ZN]',
                  'en', (), 'Europe/Berlin')" /></span>
              <span><xsl:value-of select="concat(system-property('xsl:product-name'), ' ',
                system-property('xsl:product-version'), ' from JaCoCo ', $coverageToolVersion)" /></span>
            </p>
          <section class="summary" aria-label="Overall source-file coverage">
            <xsl:for-each select="('LINE', 'BRANCH', 'METHOD')">
              <xsl:variable name="type" select="." />
              <xsl:variable name="covered" select="sum($files/counter[@type = $type]/@covered)" />
              <xsl:variable name="total" select="$covered + sum($files/counter[@type = $type]/@missed)" />
              <div><strong><xsl:value-of select="if ($total = 0) then 'N/A' else format-number($covered div $total, '0.0%')" /></strong>
                <xsl:value-of select="if ($type = 'LINE') then 'Lines' else if ($type = 'BRANCH') then 'Branches' else 'Methods'" />
                <span class="muted"><xsl:value-of select="concat(' (', $covered, '/', $total, ')')" /></span>
              </div>
            </xsl:for-each>
          </section>
          </header>
          <section id="overview" aria-label="Source file overview">
            <div class="toolbar"><div><label for="search">Filter source paths</label>
              <input id="search" type="search" placeholder="e.g. UserCon or User*Controller" autocomplete="off" autofocus="autofocus" /></div>
              <p id="count" class="muted" role="status"></p></div>
            <div class="table-container"><table>
              <thead><tr><th scope="col">Source path</th><th scope="col">Lines</th><th scope="col">Branches</th><th scope="col">Methods</th></tr></thead>
              <tbody id="files">
                <xsl:for-each select="$files">
                  <tr><td data-label="Source path"><button class="file" type="button" data-index="{position() - 1}"><xsl:value-of select="string-join((../@name[. != ''], @name), '/')" /></button></td>
                    <xsl:call-template name="counters"><xsl:with-param name="counters" select="counter" /></xsl:call-template>
                  </tr>
                </xsl:for-each>
              </tbody>
              <tfoot><tr><th scope="row">Total (all source files)</th>
                <xsl:call-template name="counters"><xsl:with-param name="counters" select="package/sourcefile/counter" /></xsl:call-template>
              </tr></tfoot>
            </table><p id="empty" hidden="hidden">No source paths match your search.</p></div>
          </section>
          <section id="source" hidden="hidden" aria-label="Source coverage">
            <button id="back" class="back" type="button">Back to files</button>
            <h2 id="path" tabindex="-1"></h2>
            <div class="legend" aria-label="Line coverage legend"><span class="covered">Covered</span><span class="partial">Partial</span><span class="missed">Missed</span><span>Non-executable</span></div>
            <p class="muted">Line tooltips: covered / total instructions and branches. Partial means some instructions or branches were missed.</p>
            <p id="unavailable" hidden="hidden">Source unavailable: not found in the configured main source roots, unreadable, or not valid UTF-8/XML text. Coverage counters remain available in the overview.</p>
            <div id="code" class="code" tabindex="0" aria-label="Source code, scroll horizontally for long lines"></div>
          </section>
          <noscript>Enable JavaScript for path filtering and embedded source navigation. The complete counter overview is shown above.</noscript>
        </main>
        <!-- JSON escaping of every less-than sign prevents source text from closing this script. -->
        <script id="coverage-data" type="application/json"><xsl:value-of select="replace(serialize(array { $data }, map {'method': 'json'}), '&lt;', '\\u003c')" /></script>
        <script><![CDATA[
          'use strict';
          const data = JSON.parse(document.getElementById('coverage-data').textContent);
          const overview = document.getElementById('overview'), source = document.getElementById('source');
          const header = document.getElementById('report-header');
          const search = document.getElementById('search'), rows = [...document.querySelectorAll('#files tr')];
          let overviewScroll = 0, lastFile = null, openedFromOverview = false;
          function filter() {
            const query = search.value.trim();
            const wildcard = query.includes('*');
            const splitWords = value => value
              .replace(/([\p{Ll}\p{N}])(\p{Lu})/gu, '$1 $2')
              .replace(/(\p{Lu})(\p{Lu}\p{Ll})/gu, '$1 $2')
              .split(' ').map(word => word.toLowerCase());
            const parts = wildcard ? query.split('*') : splitWords(query);
            const pattern = wildcard ? new RegExp(parts.map(part => part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('.*'), 'i') : null;
            let count = 0;
            rows.forEach((row, i) => {
              const path = data[i].path;
              row.hidden = !(wildcard ? pattern.test(path) : path.split(/[^\p{L}\p{N}]+/u).some(word => {
                if (parts.length === 1) return word.toLowerCase().startsWith(parts[0]) || splitWords(word).some(part => part.startsWith(parts[0]));
                const words = splitWords(word);
                let next = 0;
                for (const part of parts) {
                  while (next < words.length && !words[next].startsWith(part)) next++;
                  if (next === words.length) return false;
                  next++;
                }
                return true;
              }));
              if (!row.hidden) count++;
            });
            document.getElementById('count').textContent = `${count} of ${data.length} files`;
            document.getElementById('empty').hidden = count !== 0;
          }
          function navigate() {
            const file = data.find(item => '#file=' + encodeURIComponent(item.path) === location.hash);
            header.hidden = Boolean(file);
            if (!file) {
              overview.hidden = false; source.hidden = true;
              if (lastFile !== null) rows[lastFile].querySelector('button').focus({preventScroll:true});
              window.scrollTo(0, overviewScroll);
              return;
            }
            if (!overview.hidden) overviewScroll = window.scrollY;
            lastFile = data.indexOf(file);
            overview.hidden = true; source.hidden = false;
            document.getElementById('path').textContent = file.path;
            const code = document.getElementById('code'); code.replaceChildren();
            code.hidden = file.source === null;
            document.getElementById('unavailable').hidden = file.source !== null;
            if (file.source !== null) {
              const fragment = document.createDocumentFragment();
              const lines = file.source.split(/\r\n|\n|\r/);
              if (lines.at(-1) === '') lines.pop();
              lines.forEach((text, index) => {
                const line = document.createElement('div'); line.className = 'code-line';
                const [mi, ci, mb, cb] = file.lines[index + 1] || [0, 0, 0, 0];
                const executable = mi + ci + mb + cb > 0;
                if (executable) line.classList.add(ci + cb === 0 ? 'missed' : mi + mb > 0 ? 'partial' : 'covered');
                const state = executable ? line.classList.item(1) : 'non-executable';
                line.title = `Line ${index + 1}: ${state}. Instructions ${mi + ci ? ci + '/' + (mi + ci) : 'N/A'}; branches ${mb + cb ? cb + '/' + (mb + cb) : 'N/A'}`;
                const number = document.createElement('span'); number.className = 'number'; number.textContent = index + 1;
                number.setAttribute('aria-label', line.title);
                const content = document.createElement('span'); content.className = 'text'; content.textContent = text;
                line.append(number, content); fragment.append(line);
              });
              code.append(fragment); code.scrollLeft = 0;
            }
            window.scrollTo(0, 0); document.getElementById('path').focus({preventScroll:true});
          }
          search.addEventListener('input', filter);
          document.getElementById('files').addEventListener('click', event => {
            const button = event.target.closest('button[data-index]');
            if (button) {
              openedFromOverview = true;
              location.hash = 'file=' + encodeURIComponent(data[Number(button.dataset.index)].path);
            }
          });
          document.getElementById('back').addEventListener('click', () => {
            if (openedFromOverview) history.back();
            else location.hash = '';
          });
          window.addEventListener('hashchange', navigate);
          if ('scrollRestoration' in history) history.scrollRestoration = 'manual';
          filter(); navigate();
        ]]></script>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>

<#--
  The license-maven-plugin exposes only licenseMap and dependencyMap to this
  template. Project metadata, Maven properties, generator information, and the
  generation time therefore cannot be included in the report header. See:
  https://github.com/mojohaus/license-maven-plugin/issues/365

  Desired but unavailable report metadata:
  - project name
  - commit hash or git describe value
  - generator name and version
  - generation time in Europe/Berlin, including the time zone
-->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Dependency Licenses</title>
  <style>
    :root {
      color-scheme: light dark;
      font-family: system-ui, sans-serif;
      line-height: 1.5;
    }
    body {
      margin: 0 auto;
      max-width: 90rem;
      padding: 1rem;
    }
    h1 {
      margin-bottom: 0.25rem;
    }
    .summary {
      display: grid;
      gap: 0.75rem;
      grid-template-columns: repeat(auto-fit, minmax(8rem, 1fr));
      margin: 1.5rem 0;
    }
    .summary > * {
      border: 1px solid #8888;
      border-radius: 0.4rem;
      padding: 0.75rem;
    }
    .summary strong {
      display: block;
      font-size: 1.5rem;
    }
    .search {
      margin: 1rem 0;
    }
    .search label {
      display: block;
      font-weight: 600;
      margin-bottom: 0.25rem;
    }
    .search input {
      box-sizing: border-box;
      font: inherit;
      max-width: 30rem;
      padding: 0.5rem;
      width: 100%;
    }
    .table-container {
      overflow: visible;
    }
    table {
      border-collapse: collapse;
      width: 100%;
    }
    table, tbody, tr, td {
      display: block;
    }
    thead {
      display: none;
    }
    tbody tr {
      border: 1px solid #8888;
      border-radius: 0.4rem;
      margin-bottom: 1rem;
      padding: 0.5rem;
    }
    th, td {
      text-align: left;
      vertical-align: top;
    }
    th {
      white-space: nowrap;
    }
    td {
      overflow-wrap: anywhere;
      padding: 0.35rem;
    }
    td::before {
      content: attr(data-label);
      display: block;
      font-weight: 600;
      margin-bottom: 0.15rem;
    }
    tbody tr:hover {
      background: #8881;
    }
    [hidden] {
      display: none !important;
    }
    code {
      overflow-wrap: anywhere;
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
    }
  </style>
</head>
<body>
  <main>
    <h1>Dependency Licenses</h1>
    <p><a href="THIRD-PARTY.txt">Plain-text license report</a></p>
    <section class="summary" aria-label="Dependency summary">
      <div><strong>${dependencyMap?size}</strong>Dependencies</div>
    </section>
    <div class="search" hidden>
      <label for="dependency-search">Search dependencies</label>
      <input id="dependency-search" type="search" placeholder="Artifact, project, or license">
    </div>
    <div class="table-container">
      <table>
        <thead>
          <tr>
            <th scope="col">Artifact</th>
            <th scope="col">Version</th>
            <th scope="col">Project</th>
            <th scope="col">License</th>
          </tr>
        </thead>
        <tbody>
<#list dependencyMap as entry>
<#assign dependency = entry.getKey()>
<#assign licenses = entry.getValue()>
          <tr>
            <td data-label="Artifact"><code>${dependency.groupId?html}:${dependency.artifactId?html}</code></td>
            <td data-label="Version"><code>${dependency.version?html}</code></td>
            <td data-label="Project"><#if dependency.url??><a href="${dependency.url?html}">${dependency.name?html}</a><#else>${dependency.name?html}</#if></td>
            <td data-label="License"><#list licenses as license>${license?html}<#sep>, </#list></td>
          </tr>
</#list>
        </tbody>
      </table>
    </div>
  </main>
  <script>
    const search = document.querySelector('.search');
    const input = document.querySelector('#dependency-search');
    const rows = document.querySelectorAll('tbody tr');

    search.hidden = false;
    input.addEventListener('input', () => {
      const query = input.value.toLocaleLowerCase();
      rows.forEach((row) => {
        row.hidden = !row.textContent.toLocaleLowerCase().includes(query);
      });
    });
  </script>
</body>
</html>

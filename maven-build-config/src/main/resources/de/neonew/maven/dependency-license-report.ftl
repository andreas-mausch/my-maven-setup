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
      padding: 2rem;
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
    table {
      border-collapse: collapse;
      width: 100%;
    }
    th, td {
      border-bottom: 1px solid #8888;
      padding: 0.5rem;
      text-align: left;
      vertical-align: top;
    }
    th {
      white-space: nowrap;
    }
    tbody tr:hover {
      background: #8881;
    }
  </style>
</head>
<body>
  <main>
    <h1>Dependency Licenses</h1>
    <p>${dependencyMap?size} third-party dependencies.</p>
    <div class="search" hidden>
      <label for="dependency-search">Search dependencies</label>
      <input id="dependency-search" type="search" placeholder="Artifact, project, or license">
    </div>
    <table>
      <thead>
        <tr>
          <th scope="col">Dependency</th>
          <th scope="col">Project</th>
          <th scope="col">License</th>
        </tr>
      </thead>
      <tbody>
<#list dependencyMap as entry>
<#assign dependency = entry.getKey()>
<#assign licenses = entry.getValue()>
        <tr>
          <td><code>${dependency.groupId?html}:${dependency.artifactId?html}:${dependency.version?html}</code></td>
          <td><#if dependency.url??><a href="${dependency.url?html}">${dependency.name?html}</a><#else>${dependency.name?html}</#if></td>
          <td><#list licenses as license>${license?html}<#sep>, </#list></td>
        </tr>
</#list>
      </tbody>
    </table>
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

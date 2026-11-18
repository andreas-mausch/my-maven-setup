#!/bin/sh
# Exercise real Grype matching and HTML rendering with an isolated vulnerable SBOM.
# Never use this exception for the application image or dependency enforcement scan.
set -eu
[ "$#" -eq 3 ] || { printf 'Usage: %s EXTRACTED_RESOURCES TEST_OUTPUT EXCEPTION_FIXTURE\n' "$0" >&2; exit 1; }
resources=$1
output=$2
fixture=$3
mkdir -p "$output"
expiry=$(date -u -d '+14 days' +%Y-%m-%d)
sed "s/YYYY-MM-DD/$expiry/g" "$fixture" > "$output/exceptions.toml"
cat > "$output/vulnerable.cdx.json" <<'EOF'
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "version": 1,
  "components": [
    {
      "type": "library",
      "name": "log4j-core",
      "version": "2.14.1",
      "purl": "pkg:maven/org.apache.logging.log4j/log4j-core@2.14.1"
    }
  ]
}
EOF

# --by-cve makes the Java advisory's CVE the primary identifier for this fixture.
grype "sbom:$output/vulnerable.cdx.json" --by-cve --output json --file "$output/baseline.json"
test "$(yq -p json '.matches | map(select(.vulnerability.id == "CVE-2021-44228")) | length' "$output/baseline.json")" -eq 1
sh "$resources/prepare-container-exceptions.sh" --scan "$output/exceptions.toml" "$output/exceptions.grype.yaml" \
  "sbom:$output/vulnerable.cdx.json" --by-cve \
  --output "json=$output/accepted.json" \
  --output "template=$output/accepted.html" \
  --template "$resources/vulnerability-report.tmpl" \
  --name "$(printf 'CI exception fixture\ttest\t%s' "$(date -u +%Y-%m-%d)")"
test "$(yq -p json '.matches | map(select(.vulnerability.id == "CVE-2021-44228")) | length' "$output/accepted.json")" -eq 0
test "$(yq -p json '.ignoredMatches | map(select(.vulnerability.id == "CVE-2021-44228")) | length' "$output/accepted.json")" -eq 1
grep -Fq 'Accepted findings (1)' "$output/accepted.html"
grep -Fq '&lt;not an application approval&gt;' "$output/accepted.html"
cmp "$output/exceptions.toml" "$output/container-vulnerability-exceptions.toml"
printf 'Real Grype exception matching and Accepted report tests passed.\n'

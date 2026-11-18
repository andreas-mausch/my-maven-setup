#!/bin/sh
# Standalone validator regression tests; no Grype database or container runtime needed.
set -eu
root=$(CDPATH= cd "$(dirname "$0")/../../.." && pwd)
validator=${CONTAINER_EXCEPTIONS_VALIDATOR:-$root/src/main/resources/de/neonew/maven/prepare-container-exceptions.sh}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"
cat > "$work/bin/grype" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" > "$GRYPE_TEST_ARGS"
exit "${GRYPE_TEST_EXIT:-0}"
EOF
chmod +x "$work/bin/grype"
export PATH="$work/bin:$PATH"
export GRYPE_TEST_ARGS="$work/args"
input=$work/input.toml
output=$work/custom-build/exceptions.yaml
future=$(date -u -d '+14 days' +%Y-%m-%d)
too_far=$(date -u -d '+31 days' +%Y-%m-%d)
today=$(date -u +%Y-%m-%d)

reject() {
  printf '%s\n' "$1" > "$input"
  if sh "$validator" --scan "$input" "$output" test-source > "$work/log" 2>&1; then
    printf 'Unexpected acceptance: %s\n' "$1" >&2
    exit 1
  fi
  [ ! -e "$GRYPE_TEST_ARGS" ]
  [ ! -e "$output" ]
}

reject 'exceptions = ['
reject 'exceptions = {}'
reject 'other = []'
reject 'exceptions = [42]'
reject "exceptions = [{ cve = \"CVE-2026-1234\", expires = \"$future\", reason = \"   \" }]"
reject "exceptions = [{ expires = \"$future\", reason = \"Approved\" }]"
reject "exceptions = [{ package = \"libssl3\", version = \"*\", expires = \"$future\", reason = \"Approved\" }]"
reject "exceptions = [{ cve = \"bad\", expires = \"$future\", reason = \"Approved\" }]"
reject "exceptions = [{ cve = \"CVE-2026-1234\", expires = \"$today\", reason = \"Approved\" }]"
reject "exceptions = [{ cve = \"CVE-2026-1234\", expires = \"$too_far\", reason = \"Approved\" }]"
reject 'exceptions = [{ cve = "CVE-2026-1234", expires = "2026-02-30", reason = "Approved" }]'
reject "exceptions = [{ cve = \"CVE-2026-1234\", expires = \"$future\", reason = \"Approved\", typo = \"x\" }]"
reject "exceptions = [{ cve = \"CVE-2026-1234\", expires = \"$future\", reason = 42 }]"
reject "exceptions = [{ cve = \"CVE-2026-1234\", expires = $future, reason = \"Approved\" }]"

printf 'exceptions = []\n' > "$input"
sh "$validator" "$input" "$output"
[ "$(yq '.ignore | length' "$output")" = 0 ]
cmp "$input" "$work/custom-build/container-vulnerability-exceptions.toml"

cat > "$input" <<EOF
exceptions = [
  { cve = "CVE-2026-1234", expires = "$future", reason = 'Approved <risk> "quoted"' },
  { package = "libssl3", version = "3.5.9-r0", expires = "$future", reason = "Approved" },
  { cve = "CVE-2026-1235", package = "libcrypto3", version = "3.5.9-r0", expires = "$future", reason = "Approved" }
]
EOF
sh "$validator" --scan "$input" "$output" 'sbom:path with spaces.json' --fail-on high > "$work/log"
[ "$(yq '.ignore | length' "$output")" = 3 ]
[ "$(yq '.ignore[0] | has("package")' "$output")" = false ]
[ "$(yq -r '.ignore[1].package.name' "$output")" = '^libssl3$' ]
[ "$(yq -r '.ignore[1].package.type' "$output")" = apk ]
[ "$(yq -r '.ignore[2].vulnerability' "$output")" = CVE-2026-1235 ]
printf '%s\n' --config "$output" 'sbom:path with spaces.json' --fail-on high > "$work/expected"
cmp "$work/expected" "$GRYPE_TEST_ARGS"

# Validation failures must not overwrite the last complete configuration or run Grype.
cp "$output" "$work/previous.yaml"
rm "$GRYPE_TEST_ARGS"
printf 'exceptions = [{ reason = "Unscoped" }]\n' > "$input"
if sh "$validator" --scan "$input" "$output" test-source > "$work/log" 2>&1; then
  exit 1
fi
cmp "$output" "$work/previous.yaml"
[ ! -e "$GRYPE_TEST_ARGS" ]

# A stale generated config must not be used when the optional input disappears.
# A deliberately unusable yq proves this path does not invoke it.
cat > "$work/bin/yq" <<'EOF'
#!/bin/sh
exit 99
EOF
chmod +x "$work/bin/yq"
sh "$validator" --scan "$work/missing.toml" "$output" test-source
printf 'test-source\n' > "$work/expected"
cmp "$work/expected" "$GRYPE_TEST_ARGS"
export GRYPE_TEST_EXIT=2
if sh "$validator" --scan "$work/missing.toml" "$output" test-source; then
  exit 1
else
  [ "$?" -eq 2 ]
fi
printf 'Container exception validator tests passed.\n'

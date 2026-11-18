#!/bin/sh
# Validate project-owned TOML exceptions and retain the input and Grype configuration.
# Usage: sh prepare-container-exceptions.sh [--scan] INPUT OUTPUT [GRYPE_ARGUMENTS...]
set -euf

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

scan=false
if [ "${1:-}" = '--scan' ]; then
  scan=true
  shift
fi
[ "$#" -ge 2 ] || fail 'Usage: prepare-container-exceptions.sh [--scan] INPUT OUTPUT [GRYPE_ARGUMENTS...]'
input=$1
output=$2
shift 2

# Missing optional input preserves the ordinary scan, without requiring yq.
if [ ! -e "$input" ] && [ ! -L "$input" ]; then
  if [ "$scan" = true ]; then exec grype "$@"; fi
  exit 0
fi
[ -f "$input" ] || fail "Not an exception file: $input"
command -v yq >/dev/null 2>&1 || fail 'Mike Farah yq v4 is required for container exceptions.'
yq --version | grep -Eq 'github.com/mikefarah/yq.*version v4\.' \
  || fail 'Mike Farah yq v4 is required for container exceptions.'

date_seconds() {
  printf '%s\n' "$1" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
    || fail "Invalid UTC date: $1"
  seconds=$(TZ=UTC date -d "$1" +%s) || fail "Invalid UTC date: $1"
  [ "$(TZ=UTC date -d "$1" +%Y-%m-%d)" = "$1" ] || fail "Invalid UTC date: $1"
  printf '%s' "$seconds"
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
yq -p toml -o yaml '.' "$input" > "$work/source.yaml"
[ "$(yq -r 'tag' "$work/source.yaml")" = '!!map' ] || fail 'Expected a TOML table.'
[ "$(yq -r 'keys | .[]' "$work/source.yaml")" = 'exceptions' ] \
  || fail 'Only the exceptions table key is allowed.'
[ "$(yq -r '.exceptions | tag' "$work/source.yaml")" = '!!seq' ] \
  || fail 'exceptions must be an array.'

now=$(date -u +%s)
count=$(yq -r '.exceptions | length' "$work/source.yaml")
i=0
while [ "$i" -lt "$count" ]; do
  yq ".exceptions[$i]" "$work/source.yaml" > "$work/entry.yaml"
  entry=$work/entry.yaml
  [ "$(yq -r 'tag' "$entry")" = '!!map' ] || fail "Exception $i must be a table."
  for key in $(yq -r 'keys | .[]' "$entry"); do
    case "$key" in
      cve|package|version|expires|reason) ;;
      *) fail "Unknown exception field: $key" ;;
    esac
    [ "$(yq -r ".$key | tag" "$entry")" = '!!str' ] \
      || fail "Exception field $key must be a string (quote dates)."
  done
  cve=$(yq -r '.cve // ""' "$entry")
  package=$(yq -r '.package // ""' "$entry")
  version=$(yq -r '.version // ""' "$entry")
  until=$(yq -r '.expires // ""' "$entry")
  reason=$(yq -r '.reason // ""' "$entry")
  [ "$(printf '%s' "$cve$package$version" | wc -l)" -eq 0 ] \
    || fail 'CVE, package and version must be single-line values.'
  printf '%s\n' "$reason" | grep -q '[^[:space:]]' || fail 'An exception reason is required.'
  if [ -n "$cve" ]; then
    printf '%s\n' "$cve" | grep -Eq '^CVE-[0-9]{4}-[0-9]{4,}$' \
      || fail "Invalid CVE identifier: $cve"
  fi
  if [ -z "$package" ]; then
    [ -z "$version" ] && [ -n "$cve" ] \
      || fail 'Specify a CVE or an exact APK package version; unscoped exceptions are forbidden.'
  else
    printf '%s\n' "$package" | grep -Eq '^[a-z0-9][a-z0-9_-]*$' \
      || fail "Invalid APK package name: $package"
    printf '%s\n' "$version" | grep -Eq '^[0-9][0-9A-Za-z._+~-]*$' \
      || fail "Invalid exact APK version: $version"
  fi
  expiry=$(date_seconds "$until")
  [ "$expiry" -gt "$now" ] || fail "Expired container exception: $cve $package@$version ($until UTC)."
  [ "$expiry" -le "$((now + 30 * 24 * 60 * 60))" ] \
    || fail "Exception expiry must be at most 30 days in the future: $until."
  i=$((i + 1))
done

yq -o yaml '{"ignore": (.exceptions | map(
  {"reason": (.reason + "\nExpires: " + .expires + " (UTC)."),
   "vulnerability": .cve,
   "package": {"name": ("^" + (.package // "") + "$"), "version": .version, "type": "apk"}} |
  with_entries(select(.value != null and .value != "")) |
  with_entries(select(.key != "package" or (.value.version != null and .value.version != "")))
))}' "$work/source.yaml" > "$work/result.yaml"

# Publish only after complete validation.
mkdir -p "$(dirname "$output")"
cp "$work/result.yaml" "$output"
cp "$input" "$(dirname "$output")/container-vulnerability-exceptions.toml"
if [ "$count" -gt 0 ]; then
  printf 'WARNING: %s explicitly approved container vulnerability exception(s) are active.\n' "$count" >&2
  cat "$output"
fi
if [ "$scan" = true ]; then
  rm -rf "$work"
  trap - EXIT
  exec grype --config "$output" "$@"
fi

#!/usr/bin/env bash
# Content checks for the published legal documents.
#
# Run with no argument to check local files; pass a base URL to check the
# live site, e.g.:
#   ./verify.sh
#   ./verify.sh https://nmitchem.github.io/pltly-legal
set -uo pipefail

BASE="${1:-}"
fail=0

# -L is required, not cosmetic: the documents live at <path>/index.html, so
# GitHub Pages 301s the extensionless /privacy to /privacy/. Without -L every
# fetch returns an empty redirect body, which fails each `check` and — far
# worse — makes every `reject` pass vacuously, so a completely broken site
# still clears the placeholder gates.
fetch() {  # fetch <path>  -> stdout
  if [ -n "$BASE" ]; then
    curl -sSL --max-time 20 "$BASE/$1"
  else
    cat "./$1/index.html" 2>/dev/null
  fi
}

# Guards the vacuous-pass hole above: `reject` cannot be trusted unless the
# document actually arrived, so prove it is non-empty before asserting on it.
require_nonempty() {  # require_nonempty <path>
  if [ -z "$(fetch "$1")" ]; then
    echo "  FAIL  $1 fetched empty — every reject below would pass vacuously"
    fail=1
  fi
}

check() {  # check <label> <path> <pattern>
  if fetch "$2" | grep -qiF -- "$3"; then
    echo "  ok    $1"
  else
    echo "  FAIL  $1  (missing: $3)"
    fail=1
  fi
}

reject() {  # reject <label> <path> <pattern>
  if fetch "$2" | grep -qiF -- "$3"; then
    echo "  FAIL  $1  (must not contain: $3)"
    fail=1
  else
    echo "  ok    $1"
  fi
}

echo "Privacy policy:"
require_nonempty privacy
check "contact address"      privacy "pltly@noahmitchem.com"
check "health section"       privacy "Health data"
check "no-advertising claim" privacy "never used for advertising"
check "no-sale claim"        privacy "we do not sell"
check "no-tracking claim"    privacy "no analytics"
check "age floor"            privacy "13"
check "last updated"         privacy "Last updated"
check "links to terms"       privacy "/pltly-legal/terms"
reject "no stored-location claim" privacy "store your location"

echo "Terms of service:"
require_nonempty terms
check "age floor"            terms "13 or older"
check "24-hour commitment"   terms "24 hours"
check "fitness disclaimer"   terms "not medical advice"
check "contact address"      terms "pltly@noahmitchem.com"
check "last updated"         terms "Last updated"
check "links to privacy"     terms "/pltly-legal/privacy"

echo "Placeholders:"
for p in privacy terms; do
  for bad in "TBD" "TODO" "Lorem ipsum" "[insert" "YOUR COMPANY"; do
    reject "$p has no '$bad'" "$p" "$bad"
  done
done

if [ -n "$BASE" ]; then
  echo "Live reachability:"
  # Follow redirects and assert on the *final* status, since that is what a
  # browser and Apple's review fetcher both see. /privacy legitimately 301s to
  # /privacy/; reporting the hop keeps that visible rather than silently
  # green. What must never pass is a final code that is not 200.
  for p in "" privacy terms; do
    read -r code final < <(curl -sSL -o /dev/null \
      -w '%{http_code} %{url_effective}' --max-time 20 "$BASE/$p")
    if [ "$code" = "200" ]; then
      if [ "$final" = "$BASE/$p" ]; then
        echo "  ok    GET /$p -> 200"
      else
        echo "  ok    GET /$p -> 200 (via redirect to ${final#"$BASE"/})"
      fi
    else
      echo "  FAIL  GET /$p -> $code (final: $final)"
      fail=1
    fi
  done
fi

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAILURES PRESENT"
exit "$fail"

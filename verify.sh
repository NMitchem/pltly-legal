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

fetch() {  # fetch <path>  -> stdout
  if [ -n "$BASE" ]; then
    curl -sS --max-time 20 "$BASE/$1"
  else
    cat "./$1/index.html" 2>/dev/null
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
check "contact address"      privacy "noahmitchy@yahoo.com"
check "health section"       privacy "Health data"
check "no-advertising claim" privacy "never used for advertising"
check "no-sale claim"        privacy "we do not sell"
check "no-tracking claim"    privacy "no analytics"
check "age floor"            privacy "13"
check "last updated"         privacy "Last updated"
check "links to terms"       privacy "/pltly-legal/terms"
reject "no stored-location claim" privacy "store your location"

echo "Terms of service:"
check "age floor"            terms "13 or older"
check "24-hour commitment"   terms "24 hours"
check "fitness disclaimer"   terms "not medical advice"
check "contact address"      terms "noahmitchy@yahoo.com"
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
  for p in "" privacy terms; do
    code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE/$p")
    if [ "$code" = "200" ]; then
      echo "  ok    GET /$p -> 200"
    else
      echo "  FAIL  GET /$p -> $code"
      fail=1
    fi
  done
fi

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAILURES PRESENT"
exit "$fail"

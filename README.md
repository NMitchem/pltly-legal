# pltly-legal

Published legal documents for the Pltly iOS app, served by GitHub Pages at
<https://nmitchem.github.io/pltly-legal/>.

- `/privacy` — the URL registered in App Store Connect. Apple re-fetches it on
  every review, so it must stay reachable.
- `/terms`

This repo is public because GitHub Pages does not serve private repos on a free
plan. It contains no application source.

Run `./verify.sh` to check the local files, or
`./verify.sh https://nmitchem.github.io/pltly-legal` to check the live site.

Design rationale, including why these are not hosted on `pltly.com`, is in the
private Pltly repo at
`docs/superpowers/specs/2026-08-01-privacy-policy-tos-design.md`.

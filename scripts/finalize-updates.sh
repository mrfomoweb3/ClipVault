#!/usr/bin/env bash
#
# One-time setup: bake your GitHub username into the Sparkle update feed URL.
#
#   ./scripts/finalize-updates.sh <github-username>
#
# After this, `./scripts/release.sh <version>` will produce a signed appcast
# pointing at your repo.
#
set -euo pipefail

OWNER="${1:-}"
if [[ -z "$OWNER" ]]; then
  echo "usage: ./scripts/finalize-updates.sh <github-username>"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! grep -q "YOUR_GITHUB_USERNAME" project.yml && ! grep -q "YOUR_GITHUB_USERNAME" website/index.html; then
  echo "✓ Already finalized:"
  grep 'SUFeedURL:' project.yml
  exit 0
fi

# Feed URL baked into the app + the website's Download button.
/usr/bin/sed -i '' -E "s/YOUR_GITHUB_USERNAME/$OWNER/g" project.yml
/usr/bin/sed -i '' -E "s/YOUR_GITHUB_USERNAME/$OWNER/g" website/index.html
echo "▸ Set GitHub owner to '$OWNER':"
grep 'SUFeedURL:' project.yml
grep -o 'https://github.com/[^"]*releases/latest[^"]*' website/index.html

echo "▸ Regenerating project…"
xcodegen generate >/dev/null

echo
echo "✅ Done. Now cut a release with:  ./scripts/release.sh 1.0.2"

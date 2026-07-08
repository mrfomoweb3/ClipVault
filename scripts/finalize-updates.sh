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

if ! grep -q "YOUR_GITHUB_USERNAME" project.yml; then
  echo "✓ SUFeedURL already finalized:"
  grep 'SUFeedURL:' project.yml
  exit 0
fi

/usr/bin/sed -i '' -E "s/YOUR_GITHUB_USERNAME/$OWNER/g" project.yml
echo "▸ Set update feed owner to '$OWNER':"
grep 'SUFeedURL:' project.yml

echo "▸ Regenerating project…"
xcodegen generate >/dev/null

echo
echo "✅ Done. Now cut a release with:  ./scripts/release.sh 1.0.2"

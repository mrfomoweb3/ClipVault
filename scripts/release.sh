#!/usr/bin/env bash
#
# ClipVault release helper.
#
#   ./scripts/release.sh 1.0.1
#
# Bumps the version, builds a universal Release, packages + signs a .dmg,
# publishes it as a GitHub Release asset, and writes the signed Sparkle
# appcast (appcast.xml at the repo root). Run from the repo root.
#
set -euo pipefail

# --- args -------------------------------------------------------------------
VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "usage: ./scripts/release.sh <version>   e.g. ./scripts/release.sh 1.0.1"
  exit 1
fi
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must look like 1.2.3 (got '$VERSION')"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="ClipVault"
PROJECT="ClipVault.xcodeproj"

# --- bump version -----------------------------------------------------------
# CFBundleShortVersionString = the marketing version (1.0.1)
# CFBundleVersion            = a monotonically increasing build number
CURRENT_BUILD="$(grep -E 'CFBundleVersion:' project.yml | grep -oE '[0-9]+' | head -1)"
NEXT_BUILD=$(( CURRENT_BUILD + 1 ))

echo "▸ Bumping to v$VERSION (build $NEXT_BUILD)"
/usr/bin/sed -i '' -E \
  "s/CFBundleShortVersionString: \"[^\"]*\"/CFBundleShortVersionString: \"$VERSION\"/" project.yml
/usr/bin/sed -i '' -E \
  "s/CFBundleVersion: \"[0-9]+\"/CFBundleVersion: \"$NEXT_BUILD\"/" project.yml

# Keep the visible version label on the website in sync.
/usr/bin/sed -i '' -E \
  "s/v[0-9]+\.[0-9]+\.[0-9]+ &middot; \.dmg|v[0-9]+\.[0-9]+\.[0-9]+ · \.dmg/v$VERSION · .dmg/" website/index.html || true

# --- build ------------------------------------------------------------------
echo "▸ Generating project + building Release (universal)…"
xcodegen generate >/dev/null
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=macOS' clean build >/tmp/clipvault-build.log 2>&1 \
  || { echo "✗ build failed — see /tmp/clipvault-build.log"; tail -20 /tmp/clipvault-build.log; exit 1; }

APP="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR =/{print $3}')/$SCHEME.app"
[[ -d "$APP" ]] || { echo "✗ built app not found at $APP"; exit 1; }

# --- verify -----------------------------------------------------------------
ARCHS="$(lipo -archs "$APP/Contents/MacOS/$SCHEME")"
echo "▸ Built $APP  [$ARCHS]"

# --- package dmg ------------------------------------------------------------
# The GitHub Release asset is named ClipVault.dmg (constant) so the website's
# "latest release" download URL is stable across versions.
echo "▸ Packaging ClipVault.dmg…"
rm -rf build/dmg && mkdir -p build/dmg
cp -R "$APP" "build/dmg/$SCHEME.app"
ln -s /Applications build/dmg/Applications
DMG="build/ClipVault.dmg"
rm -f "$DMG"
hdiutil create -volname "ClipVault" -srcfolder build/dmg -ov -format UDZO "$DMG" >/dev/null
cp "$DMG" "build/ClipVault-$VERSION.dmg"   # keep a versioned local copy too

# --- figure out the repo + asset URLs ---------------------------------------
# Owner/repo are parsed from SUFeedURL: raw.githubusercontent.com/<owner>/<repo>/…
FEED="$(grep 'SUFeedURL:' project.yml | sed -E 's/.*"([^"]+)".*/\1/')"
if [[ "$FEED" == *YOUR_GITHUB_USERNAME* ]]; then
  echo "✗ SUFeedURL still has the placeholder. Run first:"
  echo "     ./scripts/finalize-updates.sh <github-username>"
  exit 1
fi
GH_PATH="${FEED#https://raw.githubusercontent.com/}"
OWNER="$(printf '%s' "$GH_PATH" | cut -d/ -f1)"
REPO="$(printf '%s' "$GH_PATH" | cut -d/ -f2)"
ASSET_URL="https://github.com/$OWNER/$REPO/releases/download/v$VERSION/ClipVault.dmg"

# --- sign the DMG -----------------------------------------------------------
echo "▸ Signing DMG with EdDSA key…"
# (first run may prompt once for Keychain access — click Allow.)
SIG_OUT="$(tools/sparkle/bin/sign_update "$DMG")"
ED_SIG="$(printf '%s' "$SIG_OUT" | sed -E 's/.*edSignature="([^"]+)".*/\1/')"
LENGTH="$(printf '%s' "$SIG_OUT" | sed -E 's/.*length="([0-9]+)".*/\1/')"
[[ -n "$ED_SIG" && -n "$LENGTH" ]] || { echo "✗ signing failed — got: $SIG_OUT"; exit 1; }

# --- publish the GitHub Release (uploads the DMG asset) ---------------------
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  echo "▸ Creating GitHub Release v$VERSION and uploading ClipVault.dmg…"
  if gh release view "v$VERSION" >/dev/null 2>&1; then
    gh release upload "v$VERSION" "$DMG" --clobber
  else
    gh release create "v$VERSION" "$DMG" \
      --title "ClipVault $VERSION" \
      --notes "ClipVault $VERSION — universal build for Apple Silicon & Intel (macOS 14+)."
  fi
else
  echo "⚠︎  gh not logged in — skipping upload. Create the release manually:"
  echo "     gh release create v$VERSION $DMG --title \"ClipVault $VERSION\""
  echo "    (the appcast below already points at the expected asset URL)"
fi

# --- write the signed appcast (repo root, committed) ------------------------
echo "▸ Updating appcast.xml…"
python3 scripts/appcast.py \
  appcast.xml "ClipVault" "$VERSION" "$NEXT_BUILD" "14.0" \
  "$ASSET_URL" "$ED_SIG" "$LENGTH"

SIZE="$(du -h "$DMG" | cut -f1 | tr -d ' ')"
echo
echo "✅ Released v$VERSION ($SIZE, $ARCHS)"
echo "   • GitHub Release asset:  $ASSET_URL"
echo "   • appcast.xml (feed):    $FEED"
echo "   • website Download btn:  https://github.com/$OWNER/$REPO/releases/latest/download/ClipVault.dmg"
echo
echo "Next:  git add appcast.xml && git commit -m \"Release v$VERSION\" && git push"
echo "       …then existing users get the update automatically via Sparkle."

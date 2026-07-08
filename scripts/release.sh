#!/usr/bin/env bash
#
# ClipVault release helper.
#
#   ./scripts/release.sh 1.0.1
#
# Bumps the version, builds a universal Release, packages a versioned .dmg,
# and drops it into website/downloads (both a versioned copy and the stable
# ClipVault-latest.dmg the site links to). Run from the repo root.
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
echo "▸ Packaging ClipVault-$VERSION.dmg…"
rm -rf build/dmg && mkdir -p build/dmg website/downloads
cp -R "$APP" "build/dmg/$SCHEME.app"
ln -s /Applications build/dmg/Applications
DMG="build/ClipVault-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "ClipVault" -srcfolder build/dmg -ov -format UDZO "$DMG" >/dev/null

# Publish the versioned DMG into the site.
cp "$DMG" "website/downloads/ClipVault-$VERSION.dmg"

# --- sign the DMG + update the Sparkle appcast ------------------------------
# Derive the download URL prefix from SUFeedURL (…/appcast.xml → …/).
FEED="$(grep 'SUFeedURL:' project.yml | sed -E 's/.*"([^"]+)".*/\1/')"
PREFIX="${FEED%appcast.xml}"
SIGN="tools/sparkle/bin/sign_update"

if [[ "$FEED" == *YOUR_GITHUB_USERNAME* ]]; then
  echo "⚠︎  SUFeedURL still has the placeholder — run:"
  echo "      ./scripts/finalize-updates.sh <github-username>"
  echo "    then re-run this release. Skipping appcast for now."
else
  echo "▸ Signing DMG with EdDSA key…"
  # sign_update prints:  sparkle:edSignature="…" length="…"
  # (first run may prompt once for Keychain access — click Allow.)
  SIG_OUT="$("$SIGN" "$DMG")"
  ED_SIG="$(printf '%s' "$SIG_OUT" | sed -E 's/.*edSignature="([^"]+)".*/\1/')"
  LENGTH="$(printf '%s' "$SIG_OUT" | sed -E 's/.*length="([0-9]+)".*/\1/')"
  if [[ -z "$ED_SIG" || -z "$LENGTH" ]]; then
    echo "✗ signing failed — got: $SIG_OUT"; exit 1
  fi
  echo "▸ Updating appcast.xml…"
  python3 scripts/appcast.py \
    website/downloads/appcast.xml \
    "ClipVault" "$VERSION" "$NEXT_BUILD" "14.0" \
    "${PREFIX}ClipVault-$VERSION.dmg" "$ED_SIG" "$LENGTH"
fi

# Stable copy the website's Download button always points at.
cp "$DMG" "website/downloads/ClipVault-latest.dmg"

SIZE="$(du -h "$DMG" | cut -f1 | tr -d ' ')"
echo
echo "✅ Released v$VERSION ($SIZE, $ARCHS)"
echo "   • $DMG"
echo "   • website/downloads/ClipVault-$VERSION.dmg   (Sparkle enclosure)"
echo "   • website/downloads/ClipVault-latest.dmg     (website Download button)"
echo "   • website/downloads/appcast.xml              (Sparkle update feed)"
echo
echo "Next:  git add -A && git commit -m \"Release v$VERSION\" && git push"
echo "       …then existing users get the update automatically via Sparkle."

#!/usr/bin/env bash
#
# Creates the "ClipVault Self-Signed" code-signing identity in your login
# Keychain. Signing every build with this stable identity means macOS keeps the
# Accessibility grant across rebuilds/updates (TCC keys on the code identity).
#
# It is NOT Gatekeeper-trusted — removing the first-launch "unidentified
# developer" warning needs a paid Apple Developer ID + notarization. This only
# fixes the "have to re-grant Accessibility after every update" problem.
#
# Run once:  ./scripts/setup-signing.sh
#
set -euo pipefail

NAME="ClipVault Self-Signed"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -p codesigning 2>/dev/null | grep -q "$NAME"; then
  echo "✓ '$NAME' already exists."
  exit 0
fi

echo "▸ Creating self-signed code-signing certificate '$NAME'…"
TMP="$(mktemp -d)"
cat > "$TMP/cert.cnf" <<EOF
[req]
distinguished_name=dn
x509_extensions=v3
prompt=no
[dn]
CN=$NAME
[v3]
basicConstraints=critical,CA:false
keyUsage=critical,digitalSignature
extendedKeyUsage=critical,codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -keyout "$TMP/k.key" -out "$TMP/c.crt" \
  -days 3650 -nodes -config "$TMP/cert.cnf" 2>/dev/null
# -legacy: macOS `security` can't read openssl 3's default PKCS12 encryption.
openssl pkcs12 -export -legacy -inkey "$TMP/k.key" -in "$TMP/c.crt" \
  -out "$TMP/id.p12" -passout pass:cv -name "$NAME" 2>/dev/null

security import "$TMP/id.p12" -k "$KEYCHAIN" -P cv -T /usr/bin/codesign
# Let codesign use the key without an interactive prompt each build.
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "" "$KEYCHAIN" >/dev/null 2>&1 || true

rm -rf "$TMP"
echo "✅ Done. The project (project.yml) already signs with '$NAME'."
echo "   Rebuild + reinstall, then grant Accessibility once — it now persists."

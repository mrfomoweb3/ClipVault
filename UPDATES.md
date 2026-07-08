# ClipVault — Releases & Auto-Updates

ClipVault ships auto-updates with [Sparkle](https://sparkle-project.org/). The app
checks an **appcast** feed hosted in this repo and installs new versions itself.

## One-time setup

1. **Create the GitHub repo** and push this project:
   ```bash
   gh auth login                         # if not already logged in
   gh repo create ClipVault --public --source=. --remote=origin
   ```

2. **Bake your GitHub username into the update feed** (replaces the placeholder
   in `project.yml`'s `SUFeedURL`):
   ```bash
   ./scripts/finalize-updates.sh <your-github-username>
   ```

3. **Cut your first update-capable release and push:**
   ```bash
   ./scripts/release.sh 1.0.2
   git add -A && git commit -m "Release v1.0.2" && git push
   ```
   The first `release.sh` run may show a **Keychain prompt** ("sign_update wants to
   access key ed25519") — click **Always Allow** once.

That's it. The feed lives at:
`https://raw.githubusercontent.com/<you>/ClipVault/main/appcast.xml`

## Every future update

```bash
./scripts/release.sh 1.0.3          # bump + build + sign + upload release + appcast
git add appcast.xml && git commit -m "Release v1.0.3" && git push
```

`release.sh` builds + signs the DMG, **creates a GitHub Release `v1.0.3` and uploads
`ClipVault.dmg` as an asset**, then writes the signed `appcast.xml`. Within a day (or
immediately via **Settings → Check for Updates…**), existing users get an
"Update Available" prompt and update themselves.

## How it fits together

| Piece | Where | Purpose |
|-------|-------|---------|
| `SUFeedURL`, `SUPublicEDKey` | `project.yml` → Info.plist | Tell the app where/how to verify updates |
| Private EdDSA key | your macOS **Keychain** | Signs each DMG (never in the repo) |
| `scripts/release.sh` | — | Bump → build → sign → **`gh release` upload** → appcast |
| `scripts/appcast.py` | — | Writes the signed `appcast.xml` entry |
| **GitHub Release assets** | `…/releases/download/v1.0.3/ClipVault.dmg` | Hosts the DMGs (kept out of git) |
| `appcast.xml` | repo root, committed (tiny) | The Sparkle update feed, served via raw.githubusercontent |

The website's **Download** button points at the stable
`…/releases/latest/download/ClipVault.dmg`, which always redirects to the newest release.

## Notes & options

- **Gatekeeper warning still applies.** Sparkle secures the *update* channel, but the
  app is still ad-hoc signed, so first-launch shows the "unidentified developer"
  caution until you sign with an **Apple Developer ID** ($99/yr) and notarize.
- **Repo stays small.** DMGs are GitHub Release assets, never committed — only the tiny
  `appcast.xml` changes each release. (`*.dmg` is git-ignored.)
- **Regenerating Sparkle tools:** they live in `tools/sparkle/bin`. If missing, re-run
  the download from the Sparkle GitHub releases page and extract into `tools/sparkle`.

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
`https://raw.githubusercontent.com/<you>/ClipVault/main/website/downloads/appcast.xml`

## Every future update

```bash
./scripts/release.sh 1.0.3          # bump + build + sign + appcast
git add -A && git commit -m "Release v1.0.3" && git push
```

Within a day (or immediately via **Settings → Check for Updates…**), existing users
get an "Update Available" prompt and update themselves. Fresh downloads keep coming
from the website's **Download** button (`ClipVault-latest.dmg`).

## How it fits together

| Piece | Where | Purpose |
|-------|-------|---------|
| `SUFeedURL`, `SUPublicEDKey` | `project.yml` → Info.plist | Tell the app where/how to verify updates |
| Private EdDSA key | your macOS **Keychain** | Signs each DMG (never in the repo) |
| `scripts/release.sh` | — | Bump → build → package → **sign** → appcast |
| `scripts/appcast.py` | — | Writes the signed `appcast.xml` entry |
| `website/downloads/` | committed to repo | Hosts the DMGs + `appcast.xml` (served via raw.githubusercontent) |

## Notes & options

- **Gatekeeper warning still applies.** Sparkle secures the *update* channel, but the
  app is still ad-hoc signed, so first-launch shows the "unidentified developer"
  caution until you sign with an **Apple Developer ID** ($99/yr) and notarize.
- **Repo size:** each release commits a ~1.4 MB DMG. To avoid slow growth you can
  delete DMGs older than the last couple of releases — users only ever download the
  newest enclosure. (Alternatively, host DMGs as GitHub Release assets instead of in
  the repo; ask and I'll switch `release.sh` to `gh release upload`.)
- **Regenerating Sparkle tools:** they live in `tools/sparkle/bin`. If missing, re-run
  the download from the Sparkle GitHub releases page and extract into `tools/sparkle`.

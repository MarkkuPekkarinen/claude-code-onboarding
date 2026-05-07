---
name: firebase-hosting-basics
description: >-
  Firebase Hosting for static SPAs and web apps. Use when configuring
  firebase.json hosting block, deploying a static site to Firebase Hosting,
  creating preview channels for PR review, or setting up GitHub Actions CI/CD
  with Workload Identity Federation. Do NOT use for Firebase App Hosting (SSR).
  Triggers: firebase hosting, deploy angular spa, firebase hosting deploy,
  preview channel, static site deploy, firebase ci/cd, hosting rewrite.
allowed-tools: Bash, Read, Write, Edit, Glob
---

## Iron Law

**NO FIREBASE HOSTING DEPLOY WITHOUT WORKLOAD IDENTITY FEDERATION.**

CI/CD uses GitHub Actions + WIF — never long-lived service account JSON keys. The
`GOOGLE_APPLICATION_CREDENTIALS` environment variable must never point to a key file
in any workflow or `.env` file.

## Project Context

Before using this skill:
- Check `CLAUDE.md` for the project's build tool and output path (e.g. `dist/`)
- Confirm the `firebase.json` location (typically repo root)
- Confirm whether a `hosting` block already exists in `firebase.json`

Build the web app before deploying:
```bash
# Adjust command to match your project's build setup
npm run build
# Confirm the output directory matches firebase.json "public" setting
```

# What are you doing?

**Configuring firebase.json?**
→ Load [references/configuration.md](references/configuration.md)
→ Set `"public"` to the project's actual build output directory

**Deploying live or to a preview channel?**
→ Load [references/deploying.md](references/deploying.md)
→ For CI/CD with GitHub Actions: Load [references/ci-cd-github-actions.md](references/ci-cd-github-actions.md)

**Adding env vars for project ID or WIF?**
→ Must sync across all env files (`.env`, `.env.staging`, `.env.production`) in the SAME PR
→ Run the project's env-sync check before committing

# References

- **Configuration:** [references/configuration.md](references/configuration.md)
- **Deploying:** [references/deploying.md](references/deploying.md)
- **CI/CD (GitHub Actions + WIF):** [references/ci-cd-github-actions.md](references/ci-cd-github-actions.md)

# Related Skills

- `angular-spa` — Angular build setup; produces the static output
- `firebase-basics` — Firebase CLI auth, project setup, npx discipline
- `gcp-cloud-run` — WIF setup patterns reused for Firebase Hosting CI/CD
- `deployment-engineer` agent — for complex multi-environment pipeline setup

# Local Development

Firebase Hosting has no local emulator equivalent — the project's dev server handles this:
```bash
# Serve locally (no Firebase needed) — adjust to project's dev command
npm run start

# Or test the production build locally
npx -y firebase-tools@latest emulators:start --only hosting
# Serves the build output at http://localhost:5000
```

---
name: supply-chain-protect
description: Proactively checks and configures package manager supply chain protections (min release age / exclude newer) whenever dependencies are installed, added, or updated. Triggers on npm, yarn, pnpm, bun, uv, pip, cargo, go, composer, bundler, deno usage.
---

# Supply Chain Protection

Protect against supply chain attacks by ensuring package managers are configured to reject freshly-published packages. New packages should "cool down" for at least 7 days before being installable — this gives the community time to detect compromised or malicious releases.

## When to trigger

Activate this skill whenever the user:

- Runs or asks you to run any package install/add/update command (e.g. `npm install`, `npm update`, `npm ci`, `yarn add`, `yarn install`, `pnpm add`, `pnpm install`, `bun add`, `bun install`, `uv add`, `uv sync`, `uv pip install`, `pip install`, `cargo add`, `go get`, `composer require`, `bundle add`, `deno add`)
- Creates or modifies dependency files (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`, `Gemfile`)
- Sets up a new project with `npm init`, `bun init`, `uv init`, `cargo init`, etc.

## What to do

### Step 1: Detect which package managers are in use

Check the project directory for lockfiles and config files. **Lockfiles take priority** — a `package.json` alone is ambiguous since npm, Yarn, pnpm, and Bun all use it. Detect in this order:

1. `bun.lock` or `bun.lockb` or `bunfig.toml` → **Bun**
2. `yarn.lock` or `.yarnrc.yml` → **Yarn Berry**
3. `pnpm-lock.yaml` or `pnpm-workspace.yaml` → **pnpm**
4. `package-lock.json` or (`package.json` with no other JS lockfile) → **npm**
5. `uv.lock` or (`pyproject.toml` with `[tool.uv]`) → **uv**
6. `requirements.txt` or `setup.py` (without uv indicators) → **pip**
7. `Cargo.toml` → **Cargo** (Rust)
8. `go.mod` → **Go**
9. `composer.json` → **Composer** (PHP)
10. `Gemfile` → **Bundler** (Ruby)
11. `deno.json` or `deno.lock` → **Deno**

A project should only match **one** JS package manager (items 1–4), but can use managers from different ecosystems simultaneously (e.g. npm for JS + uv for Python). Check all ecosystems that apply.

### Step 2: Check existing protections

For each detected package manager, check if supply chain protection is already configured:

#### npm (v11.10+)

Check `~/.npmrc` and project `.npmrc` for `min-release-age`:

```ini
min-release-age=7
```

npm does not support per-package exemptions. `min-release-age` and `--before` are **mutually exclusive** — they cannot be used together. To temporarily bypass the age gate, run with `--min-release-age=0`.

`npx` **does** respect `min-release-age` from `.npmrc` — the underlying resolver (arborist) reads the config globally.

#### Yarn Berry (v4.10+)

Check `.yarnrc.yml` for `npmMinimalAgeGate` (accepts a **duration string** — e.g. `7d` for 7 days):

```yaml
npmMinimalAgeGate: 7d
```

Supported units: `ms`, `s`, `m`, `h`, `d`, `w`. To exempt specific packages:

```yaml
npmMinimalAgeGate: 7d
npmPreapprovedPackages:
  - "@myorg/*"
```

#### pnpm (v10.16+)

Check `pnpm-workspace.yaml` for `minimumReleaseAge` (value is in **minutes**, 10080 = 7 days).

**Important:** Creating `pnpm-workspace.yaml` just for this setting (without a `packages` field) works on most versions, but **pnpm v10.31.0–v10.32.0** had a bug where all directories were treated as workspace projects (fixed in v10.32.1). On those versions, add a `packages: ["."]` field explicitly to be safe.

Config:

```yaml
minimumReleaseAge: 10080
```

pnpm also supports excluding specific packages:

```yaml
minimumReleaseAge: 10080
minimumReleaseAgeExclude:
  - "@myorg/*"
```

#### Bun (v1.3.0+)

Check `bunfig.toml` (project-level) or `$XDG_CONFIG_HOME/.bunfig.toml` / `~/.bunfig.toml` (global) for `minimumReleaseAge` (value is in **seconds**, 604800 = 7 days).

**Warning:** Bun versions before 1.3.0 **silently ignore** this setting — no error, no protection. Verify the version with `bun --version`.

```toml
[install]
minimumReleaseAge = 604800
```

Bun also supports excluding trusted packages from the age gate:

```toml
[install]
minimumReleaseAge = 604800
minimumReleaseAgeExcludes = ["@types/node", "typescript"]
```

#### uv

Check `~/.config/uv/uv.toml` (global) or `pyproject.toml` under `[tool.uv]` for `exclude-newer`:

```toml
# ~/.config/uv/uv.toml
exclude-newer = "7 days"
```

```toml
# pyproject.toml
[tool.uv]
exclude-newer = "7 days"
```

**Caveat:** Relative durations like `"7 days"` are resolved from the current time. In a **global** config (`~/.config/uv/uv.toml`) this is fine — it always means "7 days ago from now." But in a **project** config (`pyproject.toml`) committed to version control, prefer an **absolute RFC 3339 timestamp** instead (e.g. `"2026-03-24T00:00:00Z"`) so that all team members resolve the same versions when running `uv lock`. With relative durations in a shared config, two developers running `uv lock` on different days will produce different lockfiles.

#### pip (v26+) — partial support

pip supports `--uploaded-prior-to` as a CLI flag only, with **absolute timestamps** (not relative durations). There is no persistent config equivalent. Mention this limitation and recommend uv instead for Python projects.

#### Cargo, Go, Composer, Bundler, Deno — not yet supported

These package managers do **not** have native release age gating yet. If detected:

- **Cargo**: Mention RFC rust-lang/rfcs#3923 is in progress but not shipped. Suggest pinning exact versions and auditing with `cargo-audit`.
- **Go**: No equivalent exists. Suggest pinning with `go.sum` and using a module proxy.
- **Composer**: No equivalent exists. Issues have been filed (composer/composer#12552).
- **Bundler**: No native support. Mention gem.coop as a community alternative that enforces 48-hour cooldowns at the registry level.
- **Deno**: No equivalent exists. Deno relies on lockfiles (`deno.lock`) for integrity checking but has no publish-date filtering.

### Step 3: Report and offer to fix

Print a status table like:

```
Supply Chain Protection Status
==============================
npm     ✅ min-release-age=7 (in ~/.npmrc)
bun     ✅ minimumReleaseAge=604800 (in bunfig.toml)
uv      ❌ exclude-newer not set
pnpm    ⚠️  requires v10.16+, found v10.15
```

For any missing protections on supported package managers, ask the user:

> "I noticed [package manager] doesn't have supply chain protection configured. Want me to add it? This prevents installing packages published less than 7 days ago."

Then apply the appropriate config.

### Step 4: Apply the configs

When the user confirms, write the config files:

- For **global** configs (`~/.npmrc`, `~/.bunfig.toml`, `~/.config/uv/uv.toml`): append the setting if not already present, preserving existing content
- For **project** configs (`.yarnrc.yml`, `pnpm-workspace.yaml`, `bunfig.toml`, `pyproject.toml`): add the setting to the appropriate section
- Always show the user what was written and where

## Trigger behavior

- **First time in a project**: Run the full check (Steps 1–4) and report the status table.
- **Subsequent triggers**: If you've already checked this project in the current session and all protections were configured, don't repeat the full check. Only re-check if the user is setting up a new project or adding a new package manager.
- **Unsupported managers only**: If the only detected managers are unsupported (Cargo, Go, etc.), mention it briefly once. Don't repeatedly warn about something the user can't fix.

## Important notes

- Default cooldown is **7 days**. The user can customize this — respect their preference.
- Never silently modify configs. Always show what will change and ask for confirmation.
- If a package manager version is too old to support the feature, tell the user which version they need.
- For monorepos, check both root and workspace-level configs.
- These settings will cause installs to fail if a dependency was published less than 7 days ago. Warn the user this may block bleeding-edge packages and that they can exempt specific packages if needed (Yarn: `npmPreapprovedPackages`, pnpm: `minimumReleaseAgeExclude`, Bun: `minimumReleaseAgeExcludes`).

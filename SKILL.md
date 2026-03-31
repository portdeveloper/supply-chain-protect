---
name: supply-chain-protect
description: Proactively checks and configures package manager supply chain protections (min release age / exclude newer) whenever dependencies are installed, added, or updated. Triggers on npm, yarn, pnpm, bun, uv, pip, cargo, go, composer, bundler usage.
---

# Supply Chain Protection

Protect against supply chain attacks by ensuring package managers are configured to reject freshly-published packages. New packages should "cool down" for at least 7 days before being installable — this gives the community time to detect compromised or malicious releases.

## When to trigger

Activate this skill whenever the user:

- Runs or asks you to run any package install/add/update command (e.g. `npm install`, `yarn add`, `pnpm add`, `bun add`, `bun install`, `uv add`, `uv pip install`, `pip install`, `cargo add`, `go get`, `composer require`, `bundle add`)
- Creates or modifies dependency files (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`, `Gemfile`)
- Sets up a new project with `npm init`, `bun init`, `uv init`, `cargo init`, etc.

## What to do

### Step 1: Detect which package managers are in use

Check the project directory for lockfiles and config files. **Lockfiles take priority** — a `package.json` alone is ambiguous since npm, Yarn, pnpm, and Bun all use it. Detect in this order:

1. `bun.lock` or `bunfig.toml` → **Bun**
2. `yarn.lock` or `.yarnrc.yml` → **Yarn Berry**
3. `pnpm-lock.yaml` or `pnpm-workspace.yaml` → **pnpm**
4. `package-lock.json` or (`package.json` with no other JS lockfile) → **npm**
5. `uv.lock` or (`pyproject.toml` with `[tool.uv]`) → **uv**
6. `requirements.txt` or `setup.py` (without uv indicators) → **pip**
7. `Cargo.toml` → **Cargo** (Rust)
8. `go.mod` → **Go**
9. `composer.json` → **Composer** (PHP)
10. `Gemfile` → **Bundler** (Ruby)

A project can use multiple package managers (e.g. npm for JS + uv for Python). Check all that apply.

### Step 2: Check existing protections

For each detected package manager, check if supply chain protection is already configured:

#### npm (v11.10+)

Check `~/.npmrc` and project `.npmrc` for `min-release-age`:

```ini
min-release-age=7
```

#### Yarn Berry (v4.10+)

Check `.yarnrc.yml` for `npmMinimalAgeGate` (value is in **minutes**, 10080 = 7 days):

```yaml
npmMinimalAgeGate: 10080
```

To exempt specific packages:

```yaml
npmMinimalAgeGate: 10080
npmPreapprovedPackages:
  - "@myorg/*"
```

#### pnpm (v10.16+)

Check `pnpm-workspace.yaml` for `minimumReleaseAge` (value is in **minutes**, 10080 = 7 days):

```yaml
minimumReleaseAge: 10080
```

pnpm also supports excluding specific packages:

```yaml
minimumReleaseAge: 10080
minimumReleaseAgeExclude:
  - "@myorg/*"
```

#### Bun

Check `bunfig.toml` (project-level) or `~/.bunfig.toml` / `$XDG_CONFIG_HOME/.bunfig.toml` (global) for `minimumReleaseAge` (value is in **seconds**, 604800 = 7 days):

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

#### pip (v26+) — partial support

pip supports `--uploaded-prior-to` as a CLI flag only, with **absolute timestamps** (not relative durations). There is no persistent config equivalent. Mention this limitation and recommend uv instead for Python projects.

#### Cargo, Go, Composer, Bundler — not yet supported

These package managers do **not** have native release age gating yet. If detected:

- **Cargo**: Mention RFC rust-lang/rfcs#3923 is in progress but not shipped. Suggest pinning exact versions and auditing with `cargo-audit`.
- **Go**: No equivalent exists. Suggest pinning with `go.sum` and using a module proxy.
- **Composer**: No equivalent exists. Issues have been filed (composer/composer#12552).
- **Bundler**: No native support. Mention gem.coop as a community alternative that enforces 48-hour cooldowns at the registry level.

### Step 3: Report and offer to fix

Print a status table like:

```
Supply Chain Protection Status
==============================
npm     ✅ min-release-age=7 (in ~/.npmrc)
bun     ✅ minimumReleaseAge=604800 (in bunfig.toml)
uv      ❌ exclude-newer not set
pnpm    ⚠️  not supported (v10.15 < v10.16 required)
```

For any missing protections on supported package managers, ask the user:

> "I noticed [package manager] doesn't have supply chain protection configured. Want me to add it? This prevents installing packages published less than 7 days ago."

Then apply the appropriate config.

### Step 4: Apply the configs

When the user confirms, write the config files:

- For **global** configs (`~/.npmrc`, `~/.bunfig.toml`, `~/.config/uv/uv.toml`): append the setting if not already present, preserving existing content
- For **project** configs (`.yarnrc.yml`, `pnpm-workspace.yaml`, `bunfig.toml`, `pyproject.toml`): add the setting to the appropriate section
- Always show the user what was written and where

## Important notes

- Default cooldown is **7 days**. The user can customize this — respect their preference.
- Never silently modify configs. Always show what will change and ask for confirmation.
- If a package manager version is too old to support the feature, tell the user which version they need.
- For monorepos, check both root and workspace-level configs.
- These settings will cause installs to fail if a dependency was published less than 7 days ago. Warn the user this may block bleeding-edge packages and that they can exempt specific packages if needed (Yarn: `npmPreapprovedPackages`, pnpm: `minimumReleaseAgeExclude`, Bun: `minimumReleaseAgeExcludes`).

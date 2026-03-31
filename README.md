# supply-chain-protect

An AI agent skill that guards your dependencies. Every time you install a package, it checks if your package manager is configured to reject freshly-published versions — and offers to fix it if not.

New packages "cool down" for 7 days before they're installable. This gives the community time to catch compromised releases before they hit your `node_modules`, `.venv`, or lockfile.

```
npx skills add portdeveloper/supply-chain-protect
```

## How it works

```
  you type                        the skill
  "bun add zod"        ──>     checks bunfig.toml
                                     │
                               is minimumReleaseAge set?
                              /                        \
                            yes                         no
                             │                           │
                        installs                    asks you:
                        normally              "want me to add it?"
                                                     │
                                               writes config
                                               shows diff
```

When the skill triggers, it prints a status report:

```
Supply Chain Protection Status
══════════════════════════════
 npm     ✅  min-release-age=7 (in ~/.npmrc)
 bun     ✅  minimumReleaseAge=604800 (in bunfig.toml)
 uv      ❌  exclude-newer not set
 pnpm    ⚠️   requires v10.16+, found v10.15
```

## Supported package managers

| Package Manager | Config | Unit |
|---|---|---|
| **npm** v11.10+ | `min-release-age=7` in `.npmrc` | days |
| **Yarn Berry** v4.10+ | `npmMinimalAgeGate: 7d` in `.yarnrc.yml` | duration string |
| **pnpm** v10.16+ | `minimumReleaseAge: 10080` in `pnpm-workspace.yaml` | minutes |
| **Bun** v1.3.0+ | `minimumReleaseAge = 604800` in `bunfig.toml` | seconds |
| **uv** | `exclude-newer = "7 days"` in `uv.toml` | duration / timestamp |

Also provides guidance for pip, Cargo, Go, Composer, Bundler, and Deno (no native support yet).

## Tested against

Every config in this skill was tested against real package managers:

| Manager | Version tested | Blocking | Exemptions |
|---|---|---|---|
| npm | 11.11.0 | `ENOVERSIONS` error | `--min-release-age=0` to bypass |
| Yarn Berry | 4.10.0 | "No candidates found" | `npmPreapprovedPackages` |
| pnpm | 10.28.2 | Clear error with age info | `minimumReleaseAgeExclude` |
| Bun | 1.3.11 | Per-package block reason | `minimumReleaseAgeExcludes` |
| uv | 0.10.9 | Resolution fails cleanly | Use absolute timestamp |

> **Note:** Bun < 1.3.0 silently ignores the setting — no error, no protection.

## Install

```bash
npx skills add portdeveloper/supply-chain-protect
```

Works with Claude Code, Cursor, Codex, GitHub Copilot, Gemini CLI, and [40+ other agents](https://skills.sh).

## License

MIT

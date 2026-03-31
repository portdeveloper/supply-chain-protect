# supply-chain-protect

An AI agent skill that proactively checks and configures package manager supply chain protections whenever you install, add, or update dependencies.

## What it does

When you use any package manager, this skill checks if you have **minimum release age** / **exclude newer** protections configured. If not, it offers to set them up. This prevents installing packages published less than 7 days ago — giving the community time to detect compromised or malicious releases.

## Supported package managers

| Package Manager | Support | Config |
|---|---|---|
| **npm** (v11.10+) | Full | `min-release-age=7` in `.npmrc` |
| **Yarn Berry** (v4.10+) | Full | `npmMinimalAgeGate: 7d` in `.yarnrc.yml` |
| **pnpm** (v10.16+) | Full | `minimumReleaseAge: 10080` in `pnpm-workspace.yaml` |
| **Bun** | Full | `minimumReleaseAge = 604800` in `bunfig.toml` |
| **uv** | Full | `exclude-newer = "7 days"` in `uv.toml` |
| **pip** (v26+) | Partial | `--uploaded-prior-to` CLI flag only |
| **Cargo** | Guidance | RFC in progress, not yet shipped |
| **Go** | Guidance | No native support |
| **Composer** | Guidance | No native support |
| **Bundler** | Guidance | No native support (gem.coop workaround) |
| **Deno** | Guidance | No native support |

## Install

```bash
npx skills add portdeveloper/supply-chain-protect
```

## License

MIT

# Tweet draft

made an AI agent skill that protects you from supply chain attacks

every time you install a package, it checks if your package manager has a minimum release age configured — and offers to set it up if not

works with npm, yarn, pnpm, bun, and uv

npx skills add portdeveloper/supply-chain-protect

tested every config against the real package managers. bun < 1.3.0 silently ignores the setting btw — no error, no protection

---

# ASCII art (screenshot this in terminal)

```
┌─────────────────────────────────────────────────────────┐
│              supply-chain-protect                        │
│         AI agent skill for safe installs                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   you: "npm install foo"                                │
│                 │                                       │
│                 ▼                                       │
│   ┌─────────────────────────┐                           │
│   │ is min-release-age set? │                           │
│   └────────┬────────┬───────┘                           │
│          yes        no                                  │
│            │         │                                  │
│            ▼         ▼                                  │
│       ✅ safe    "Want me to add                        │
│       install    min-release-age=7                      │
│                  to your .npmrc?"                       │
│                       │                                 │
│                       ▼                                 │
│              ┌──────────────┐                           │
│              │ writes config│                           │
│              │ shows diff   │                           │
│              └──────────────┘                           │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  Supply Chain Protection Status                         │
│  ══════════════════════════════                         │
│   npm   ✅ min-release-age=7         (.npmrc)           │
│   bun   ✅ minimumReleaseAge=604800  (bunfig.toml)     │
│   yarn  ✅ npmMinimalAgeGate: 7d     (.yarnrc.yml)     │
│   pnpm  ✅ minimumReleaseAge: 10080  (pnpm-workspace)  │
│   uv    ❌ exclude-newer not set                        │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  npx skills add portdeveloper/supply-chain-protect      │
└─────────────────────────────────────────────────────────┘
```

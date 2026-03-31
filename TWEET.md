# Tweet draft

the axios hack worked because a malicious dependency was published to npm minutes before being pulled into the package. a 7-day minimum release age would have stopped it cold.

i built an AI agent skill that checks this for you. every time you install a package, it looks at whether your package manager has min-release-age configured — and offers to set it up if not.

works with npm, yarn, pnpm, bun, and uv.

npx skills add portdeveloper/supply-chain-protect

i tested every config against the actual package managers. fun fact: bun < 1.3.0 silently ignores the setting — no error, no protection.

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

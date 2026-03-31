# Tweet 1

the axios attack used a dependency that had been on npm for minutes. a 7-day minimum release age would've stopped it.

paste this into your AI agent:

"Read https://portdeveloper.github.io/supply-chain-protect/SKILL.md and protect my project"

it detects which package managers you use, checks if you have min-release-age configured, and sets it up if not.

# Tweet 2 (reply)

the fun part: every package manager chose a different unit for the same 7-day setting

npm: min-release-age=7 (days)
yarn: npmMinimalAgeGate: 7d (duration string)
pnpm: minimumReleaseAge: 10080 (minutes)
bun: minimumReleaseAge = 604800 (seconds)
uv: exclude-newer = "7 days"

the skill handles all of them. tested against npm 11.11, yarn 4.10, pnpm 10.28, bun 1.3.11, and uv 0.10.9.

also works via skills.sh:
npx skills add portdeveloper/supply-chain-protect

github.com/portdeveloper/supply-chain-protect

# ki-tools

Audit, conform, or scaffold a Knowledge Islands `tools-*` repo — ONE standalone command-line tool per repo, distributed by a `curl | bash` installer AND a companion Homebrew tap formula.

**Invoke:** `ki-tools audit <repo> | conform <repo> | help | init <repo> | refresh`

**Modes:**

- `AUDIT  `
- `CONFORM`
- `HELP   ` — explain this skill and stop; the default when no mode is given (then routes, if interactive)
- `INIT   `
- `REFRESH`

**See also:** the Homebrew tap + its formula → `ki-homebrew-tap`; GitHub settings and standard files (README, LICENSE) → `ki-repo`; a TS/Bun toolchain (`package.json`) → `ki-engineering`. Container, not contents — it does not judge the tool's internal code quality.

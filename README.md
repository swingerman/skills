# Claude Code skills & plugins

A personal marketplace of [Claude Code](https://docs.claude.com/en/docs/claude-code) plugins.

## Install the marketplace

```bash
/plugin marketplace add swingerman/skills
```

Then install individual plugins:

```bash
/plugin install crap-analyzer@swingerman-skills
```

## Plugins

### [crap-analyzer](plugins/crap-analyzer)

Analyze recently-changed code for Change Risk Anti-Patterns (CRAP = complexity × untested-ness). Flags the worst-risk functions in a diff and proposes refactors + test stubs.

- **Languages:** TypeScript, JavaScript, Python, Java, Kotlin, Go, Ruby, C#, Rust, PHP
- **Coverage formats:** lcov, Cobertura, JaCoCo, Clover, Go `coverage.out`, coverage.py JSON
- **Auto-discovers** how the repo generates coverage (`package.json`, `pyproject.toml`, Maven/Gradle, `go.mod`, etc.)

Trigger with phrases like *"analyze CRAP"*, *"check code risk on this branch"*, or by running `/crap-analyzer` in a repo with a diff.

## Repo layout

```
.
├── .claude-plugin/
│   └── marketplace.json         # marketplace manifest
└── plugins/
    └── crap-analyzer/
        ├── .claude-plugin/
        │   └── plugin.json      # plugin manifest
        └── skills/
            └── crap-analyzer/   # skill content
                ├── SKILL.md
                ├── scripts/
                └── references/
```

## License

MIT — see [LICENSE](LICENSE).

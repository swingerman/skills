---
name: crap-analyzer
description: Analyze recently-changed code for Change Risk Anti-Patterns (CRAP) and propose fixes. Computes CRAP = comp² × (1 − cov)³ + comp per changed function using heuristic cyclomatic complexity and test coverage. Works across languages — TypeScript, JavaScript, Python, Java, Kotlin, Go, Ruby, C#, Rust, PHP — and auto-discovers how the repo generates coverage. Use when the user asks to "analyze CRAP", "check code risk", "find risky methods", "compute CRAP on this diff/branch/PR", "run /crap-analyzer", or otherwise wants a risk-based refactor + test plan for recently-changed code. Scope is the diff only — not the whole codebase. Produces a ranked markdown report, proposes extract-method refactors as unified diffs, generates test stubs for uncovered branches, and optionally auto-applies safe refactors after per-change confirmation.
---

# CRAP Analyzer

CRAP (Change Risk Anti-Patterns) flags functions that are both **complex** and **poorly tested** — the worst-risk code to ship. Formula:

```
CRAP(m) = comp(m)^2 * (1 - cov(m))^3 + comp(m)
```

This skill scopes analysis to a diff (PR, branch, or staged changes), ranks findings worst-first, and turns each finding into a concrete refactor + test-stub proposal.

## Workflow

1. **Determine the diff.** Pick the first that works:
   - `gh pr diff` / `gh pr diff <number>` if the user references a GitHub PR.
   - `git diff --merge-base <main-branch>` where `<main-branch>` is whichever of `main`, `master`, `develop`, `trunk` exists on the remote (`git remote show origin | grep 'HEAD branch'` is authoritative).
   - `git diff --cached` for staged changes.
   - `git diff HEAD~N..HEAD` for the last N commits if the user names a range.
   - Explicit file list if the user names files.

   Pipe the diff to `scripts/compute_crap.py --diff -`.

2. **Locate or generate coverage.** First let the script auto-discover coverage files (see [Coverage formats the script understands](#coverage-formats-the-script-understands)). If nothing is found, **discover how this repo generates coverage** (see [Discovering the coverage toolchain](#discovering-the-coverage-toolchain) and [references/coverage-discovery.md](references/coverage-discovery.md)), then offer to run it scoped to the changed files. Wait for a yes before running. If the user declines, proceed with coverage=0% and call this out explicitly in the report header.

3. **Run the analyzer.**
   ```bash
   python3 <skill-dir>/scripts/compute_crap.py \
     --diff - --repo-root <repo> --threshold <N> --format both
   ```
   Default threshold is 20. Accept `.crap-analyzer.json` at repo root with `{ "threshold": N }` and pass through. Script prints JSON to stdout and markdown to stderr.

4. **Present the report.** Show the markdown table. For each finding, link `file:start_line`. If more than ~8 findings, surface the top 5 and mention the rest.

5. **Propose fixes per finding, worst-first.** For each function above threshold:
   - **Read the function.** Don't rely on the score alone — look at the actual code.
   - **Refactor proposal.** Draft an extract-method diff or guard-clause rewrite. See [references/refactor-patterns.md](references/refactor-patterns.md) for patterns.
   - **Test stubs.** Generate stubs covering each uncovered branch in the framework the repo uses. See [references/test-stub-templates.md](references/test-stub-templates.md) for templates per framework (Jest/Vitest, pytest, JUnit, Go `testing`, RSpec, xUnit).
   - **Respect the codebase's conventions.** Read nearby code first and match its style (naming, error handling, DI, async patterns). Don't rewrite idioms the project has chosen.

   **When there are 3 or more findings, dispatch subagents in parallel** — one per finding — instead of drafting them sequentially. Each finding is independent (read function → draft refactor → draft stubs), so parallelizing drops wall-clock time from O(n) to O(1) and keeps the main conversation context from ballooning. See [Parallel per-finding analysis](#parallel-per-finding-analysis) for the dispatch contract.

6. **Per-change confirmation for auto-apply.** "Safe refactor" = pure extract-method with no behavior change (same inputs → same outputs, same side effects, same order). For each safe refactor, ask the user "apply this one?" and use Edit only after yes. Never bundle multiple functions into a single apply.

7. **Never auto-apply:**
   - Changes that reorder side effects or async operations (`await`, `.then`, `subscribe`, promise chains, RxJS/coroutine/goroutine ordering).
   - Changes to constructors, initializers, or lifecycle hooks without the user seeing the diff first.
   - Changes to reactive/stream operator ordering.
   - Template / markup / view changes (the script doesn't analyze templates — those are always manual).

## Parallel per-finding analysis

When `len(findings) >= 3`, draft per-finding proposals in parallel by issuing multiple `Agent` tool calls in a **single message**. Sequential dispatch defeats the point.

**Per-subagent prompt template** (each is self-contained — subagents can't see the main conversation):

> **Draft a refactor + test stubs for one CRAP finding.**
>
> **Finding:** `<file>:<start_line>` — `<name>` (`<kind>`, `<language>`). Complexity `<N>`, coverage `<pct>%` (`<covered>/<executable>` lines), CRAP score **`<crap>`**.
>
> **File to read:** `<absolute path to source file>`. Read the entire file for context, then focus on lines `<body_start_line>–<body_end_line>`.
>
> **Test framework in this repo:** `<Jest | pytest | JUnit 5 | Go testing | RSpec | …>`. Test file convention: `<e.g. alongside source as *.spec.ts>`.
>
> **Codebase conventions to respect:** `<2–3 bullets from the repo — e.g. "uses pytest fixtures", "async errors return Result<E>", "DI via constructor">`. Read nearby files if you need more context.
>
> **Deliverable** — one markdown block in exactly this shape:
> ```markdown
> ### `<file>:<line>` — `<name>` (CRAP `<score>`)
>
> **Why it's flagged:** <one sentence naming the dominant factor — complexity, coverage, or both — and pointing at the specific branches>.
>
> **Refactor proposal:**
> <unified diff OR fenced code block of the proposed replacement; pick whichever is clearer for the change>
>
> **Safe to auto-apply?** <yes | no — reason if no, per the rules in SKILL.md step 7>
>
> **Test stubs to add:**
> <framework-appropriate fenced block with at least one real assertion per stub>
> ```
>
> Keep it tight — one paragraph of "why", the diff, the stubs. No preamble, no alternatives, no "you could also…". If the function is already fine and the high CRAP comes purely from missing tests, skip the refactor block and say so.

**Aggregation by the main agent:**

1. Wait for all subagents to return.
2. Sort results by CRAP score descending (same order as the findings table).
3. Print them back-to-back under the report table, unchanged.
4. **Sanity-check each "safe to auto-apply" claim** against step 7 — subagents sometimes mislabel. Downgrade to "no" if you see a reordered async op, a touched constructor, or a split across a `try` boundary.
5. Continue to the wrap-up menu (step 6).

**When to skip parallel dispatch:**

- `len(findings) < 3` — subagent spin-up overhead eats the win.
- User asked for a quick scan only ("just show me the scores") — skip step 5 entirely.
- The same function appears twice (e.g. overloaded methods across files) — handle it once, inline.

**Tool-use hygiene:** all Agent calls in the same message, each with a self-contained prompt (the subagent can't see this skill or the conversation). Pass absolute paths, not relative ones. Don't include the full diff in the prompt — the subagent only needs the finding metadata and the file path.

## Discovering the coverage toolchain

When no coverage file is found, introspect the repo to figure out how to generate one. Ask first: *"No coverage file found. Want me to run tests with coverage? (This may take a few minutes.)"* If yes, detect the toolchain and scope to changed files where the runner supports it.

### Detection signals (in priority order)

Read the repo root once. The **first match wins**; multiple can coexist in polyglot repos and you should handle each ecosystem separately for the files it owns.

| Signal | Ecosystem | Runner |
|---|---|---|
| `package.json` with `scripts.coverage` or `scripts["test:coverage"]` | JS/TS | Use that script verbatim |
| `jest.config.*` or `"jest"` key in `package.json` | JS/TS | Jest (`npx jest --coverage`) |
| `vitest.config.*` or `vitest` in `devDependencies` | JS/TS | Vitest (`npx vitest run --coverage`) |
| `nx.json` | JS/TS monorepo | Nx (`npx nx test <project> --coverage`) |
| `karma.conf.*` or `@angular-devkit/build-angular:karma` in `angular.json` | JS/TS (Angular) | Karma (`npx ng test --watch=false --code-coverage`) |
| `.nycrc*` or `nyc` in `package.json` | JS/TS | nyc/istanbul (`npx nyc <test-cmd>`) |
| `pyproject.toml` with `[tool.pytest.ini_options]` or `[tool.coverage.*]` | Python | pytest + coverage.py |
| `pytest.ini` / `setup.cfg` with `[tool:pytest]` | Python | pytest |
| `tox.ini` | Python | tox (look for coverage envs) |
| `pom.xml` with JaCoCo plugin | Java | Maven + JaCoCo (`mvn test`) |
| `build.gradle` / `build.gradle.kts` with `jacoco` plugin | Java/Kotlin | Gradle + JaCoCo (`./gradlew test jacocoTestReport`) |
| `go.mod` | Go | `go test -coverprofile=coverage.out ./...` |
| `Gemfile` with `rspec` / `simplecov` | Ruby | RSpec + SimpleCov (`bundle exec rspec`) |
| `Cargo.toml` | Rust | `cargo llvm-cov` or `cargo tarpaulin` |
| `*.csproj` with `coverlet.*` | C# | `dotnet test --collect:"XPlat Code Coverage"` |
| `composer.json` with `phpunit` | PHP | PHPUnit (`vendor/bin/phpunit --coverage-xml=...`) |
| `Makefile` / `justfile` / `Taskfile.yml` with a `coverage` / `test-cov` target | Any | Prefer the repo's own target |

**Always prefer the repo's own coverage script** when it exists — it's the maintainer's canonical command and is likely wired into CI.

See [references/coverage-discovery.md](references/coverage-discovery.md) for full commands per ecosystem, including how to scope to changed files and where coverage output lands.

### Scoping to changed files

Scoping to changed files is nice to have, not required. If the runner can't filter, run the suite.

- **Jest/Vitest:** `npx jest --coverage --findRelatedTests <changed-files>` walks the import graph.
- **pytest:** `pytest --cov=<pkg> path/to/test_changed.py` or rely on `--cov` with `testpaths` config.
- **Go:** `go test -coverprofile=coverage.out ./pkg/affected/...`
- **JaCoCo / Karma / RSpec:** run the whole suite — scoping is awkward and usually slower than it's worth.

### When not to run tests

- User said no.
- No test configuration found.
- Running would require external services the skill can't verify are up (databases, queues, remote APIs).
- Tests are known to be broken on the branch.

In those cases, run the analyzer with coverage=0% and make the limitation obvious in the report header.

## Coverage formats the script understands

Auto-discovery walks `coverage/` and the repo root looking for:

| Format | Typical path | Emitted by |
|---|---|---|
| **lcov** (`lcov.info`) | `coverage/lcov.info`, `coverage/<project>/lcov.info` | Jest, Vitest, nyc, Karma, simplecov-lcov, `cargo llvm-cov` |
| **Cobertura XML** | `coverage.xml`, `coverage/cobertura-coverage.xml` | coverage.py, coverlet, phpunit, gocover-cobertura |
| **JaCoCo XML** | `target/site/jacoco/jacoco.xml`, `build/reports/jacoco/test/jacocoTestReport.xml` | Maven, Gradle (Java/Kotlin) |
| **Clover XML** | `coverage.xml`, `clover.xml` | PHPUnit, nyc |
| **Go coverage** | `coverage.out` | `go test -coverprofile=...` |
| **coverage.py JSON** | `coverage.json` | `coverage json` |

Pass `--lcov <path>` (the flag name is historical — it accepts any supported format) to override auto-discovery.

## Report format

Copy the script's markdown table verbatim. Then add a section per finding:

```markdown
### 1. `file.py:42` — `do_thing` (CRAP 240)

**Why it's flagged:** complexity 15, coverage 0% (no tests touching body).

**Refactor proposal:**
<unified diff or code block>

**Test stubs to add:**
<framework-appropriate test block>
```

Keep each section tight. One paragraph of "why", diff, stubs. No preamble.

## Wrap-up actions

After the report and per-finding proposals are on screen, present an **actionable menu** via `AskUserQuestion` so the user can dispatch work in one step. Do this every time, even if there's only one finding.

### Global menu (always shown first)

Ask one multi-select question with these options:

| Header | Option label | What it does |
|---|---|---|
| Refactors | Apply safe refactors for **all** findings | Iterate findings, apply only the refactors marked safe in [refactor-patterns.md](references/refactor-patterns.md), one Edit per function |
| Refactors | Apply safe refactors for the **top N** | Ask a follow-up for N, then apply to the top-N by CRAP score |
| Tests | Add test stubs for **all** findings | Create or extend the test file next to each source file using templates from [test-stub-templates.md](references/test-stub-templates.md) |
| Tests | Add test stubs for **top N** | Ask for N, then stub only those |
| Per-item | Pick per finding | Drop into the per-finding loop below |
| Skip | Skip — report only | Leave code untouched |

Phrasing for the prompt: *"How should I address these findings?"* — multi-select true so the user can combine (e.g. "safe refactors for top 3" + "tests for all").

### Per-finding loop

If the user picked "Pick per finding", walk findings worst-first and ask one multi-select per function:

*"`funcName` at `file:line` (CRAP N) — what should I do?"*

Options:
- Apply the proposed refactor
- Add the proposed test stubs
- Skip this function
- Stop — no more per-item prompts (exits the loop, reports what was applied so far)

Between iterations, keep the message terse: name, file:line, score, action taken. Do not re-print the full diff the user already saw.

### Execution rules

- **One Edit per action.** Never bundle multiple functions into a single tool call.
- **Refactor before tests for the same function.** Stub examples should reference the final names.
- **Run the test stubs you just added** if the user has a test runner and accepts. Use the framework's most-scoped command (e.g. `jest --findRelatedTests`, `pytest path/to/test.py::TestClass`, `go test -run TestName`). Failures after stubbing are expected — flag them and let the user fill in assertions.
- **Re-run the analyzer at the end** if any refactor or test was applied. Show before/after CRAP scores side-by-side in a short summary.

### Summary line format

After the menu loop ends, print one summary block:

```markdown
## Wrap-up

- Refactored: 3 function(s) — `foo`, `bar`, `baz`
- Tests stubbed: 5 spec file(s) — see `test_*.py` / `*.spec.ts` / `*_test.go` alongside sources
- Skipped: 2 function(s) — `qux` (user skipped), `quux` (no safe refactor available)

Re-run CRAP: top score dropped from **240 → 43**, 4 findings → 1.
```

## Config file

Optional `.crap-analyzer.json` at repo root:

```json
{ "threshold": 20 }
```

Read it if present, pass `--threshold` to the script. No other keys for now.

## When not to use this skill

- Analyzing a full codebase unprompted — scope is diff-only by design.
- Running as a blocking gate in CI — this is a Claude-driven review, not a deterministic check.
- Files the script doesn't recognize (see [Script reference](#script-reference) for supported extensions). Binaries, generated code, config files are skipped automatically.

## Script reference

`scripts/compute_crap.py`

| Flag | Description |
|---|---|
| `--diff PATH\|-` | Unified diff to analyze. `-` reads stdin. Required. |
| `--repo-root DIR` | Repository root (default: cwd). |
| `--lcov PATH` | Explicit coverage file (any supported format). Auto-discovered if omitted. |
| `--threshold N` | Minimum CRAP score to report (default: 20). |
| `--format json\|md\|both` | Output format. `both` prints JSON to stdout, markdown to stderr. |

**Supported source extensions:** `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs`, `.py`, `.java`, `.kt`, `.kts`, `.go`, `.rb`, `.cs`, `.rs`, `.php`. Test files (`*.spec.*`, `*.test.*`, `test_*.py`, `*_test.go`, `*Test.java`, etc.) are skipped.

Output JSON shape:
```json
{
  "threshold": 30.0,
  "coverage_file": "/abs/path/to/lcov.info",
  "coverage_format": "lcov",
  "findings": [
    {
      "file": "src/app/foo.py",
      "name": "do_thing",
      "kind": "function",
      "language": "python",
      "start_line": 42,
      "end_line": 87,
      "complexity": 15,
      "coverage": 0.5,
      "executable_lines": 16,
      "covered_lines": 8,
      "crap": 43.12
    }
  ]
}
```

### Accuracy caveats

The script uses regex-based heuristics, not real parsers. That means:

- Decision points inside string interpolations (`${a ?? b}`, f-strings) aren't counted.
- Deeply nested closures/lambdas may confuse function-boundary detection in edge cases.
- Language-specific subtleties (Python decorators with arguments, Kotlin `when` arms, Go type switches) are counted best-effort.
- Generated code, heavy macro usage, and DSL-like code may be miscounted.

Close enough to rank findings. If a specific score looks wrong, read the function and trust your eyes.

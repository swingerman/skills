# intent

Turn a rough idea into a standard **intent**: **What / Why / Guardrails / Done means**. The result is a self-contained prompt you can hand to an agent or save to a file.

## Install

```bash
/plugin marketplace add swingerman/skills
/plugin install intent@swingerman-skills
```

## Usage

```
/intent add dark mode to the settings page
```

The skill interviews you in layers:

1. **Parse**: maps your prompt onto the four sections and marks what's missing or vague. No questions yet.
2. **High-level gaps**: at most one question per weak section, each with a recommended answer.
3. **Depth gate**: recommends *go deeper* or *stop*, with a reason. You decide.
4. **Section drill / scenarios**: only if you opt in (max 3 layers).

Answers about *how* get pushed out. An intent says what and why, never how.

## Output

```markdown
# Intent: Dark mode for settings

## What
…
## Why
…
## Guardrails
- Must: …
- Must not: …
- Out of scope: …
## Done means
- [ ] …
## Assumptions & open questions
- (assumed) …
- (open) …
```

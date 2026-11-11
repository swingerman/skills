---
name: surface-skills
description: Map a project's features into per-surface agent skills — one skill per client/backend with launch, health check, drive and cleanup at the root, a references/features.md map, and a README per feature (user POV, where, how to use, keys, API, code, verify, debug, gotchas) — plus a drift check that fails the build when the map goes stale. Use on any repo. Triggers — "map the features for agents", "make skills for each part of the app", "how does an agent verify feature X", "surface skills", "feature map skill", "document how to launch and verify this app".
---

# surface-skills

Give every agent that lands in a repo the same three answers, without reading the code base first:
**how do I run this part**, **where is feature X**, **how do I prove X works**.

Output, inside the target repo:

```
.claude/skills/<project>-<surface>/
  SKILL.md                  launch, doctor, logs, drive, evidence, cleanup  (references/surface-template.md)
  references/features.md    every feature on this surface, one block each   (references/features-template.md)
  <feature>/README.md       one per feature                                  (references/feature-template.md)
```

Claude Code discovers skills one level deep only (`.claude/skills/<name>/SKILL.md`). Feature folders are reference files the root routes to, not skills; the root's description must carry the triggers.

## 0. Before writing anything

- Read the repo's agent instructions (CLAUDE.md, AGENTS.md, CONTRIBUTING, README). Obey its rules on branches/worktrees. Do the work on a branch or in a worktree, never on the default branch of the main checkout.
- Find what must never be disturbed: the developer's running instance (its ports, its config/data dirs, its database). Every recipe you write must avoid all of it.
- Look for an existing verify/run skill. Fold it in and keep its name as a short pointer if other tooling finds it by name.
- Look for words the repo bans (name checks, lint rules). Feature docs are tracked files.

## 1. Find the surfaces

A surface is something that runs and that a user or another program talks to: a web/desktop/mobile client, an API server, a worker, a relay, a CLI, a library's public API. Signals: `package.json`/`pyproject`/`go.mod` per dir, entrypoints, Dockerfiles, deploy configs, separate tsconfigs.

One skill per surface. Name them `<project>-<surface>` so they don't collide with other repos' skills. Fewer is better: merge two dirs into one surface when they always run together.

## 2. Inventory each surface from the code, not from memory

Collect the lists the drift check will later enforce. Take each from the code that defines it:

| Surface kind | What to list | Where it usually lives |
|---|---|---|
| HTTP API | routes (method + path) | router files, framework decorators |
| socket / message API | message `type`s handled | the dispatch `switch`/handler map |
| RPC / MCP / tools | tool or procedure names | registration calls |
| CLI | commands and flags | arg-parser definitions |
| UI | views/routes, key bindings | router, keymap table |
| jobs/workers | job names, schedules | queue registration, cron config |

Then group those entries into **features**, meaning what a user would call one thing. Use README sections, UI views and spec folders as hints. Aim for 10–30 per surface. Every inventory entry belongs to exactly one feature.

## 3. Write the surface root (SKILL.md)

Follow `references/surface-template.md`. Requirements learned from evals:

- **Launch on its own ports with a throwaway config/data dir.** Give exact env vars. Record the pid and stop by pid. Never kill by port.
- **Doctor:** one command that exits 0 only when the instance is healthy, and what to read when it isn't.
- **Runtime fallback:** if the system runtime (`node`, `python`, …) is broken or the wrong version, look in the version managers (fnm/nvm/volta/asdf/mise/pyenv). Never hard-code one machine's path.
- **Verify the checkout's own build, never the running instance.** Not even read-only GETs. Never point the throwaway instance at the real config/data dir. Agents that skipped this tested the installed app, not the code.
- **Drive:** how to talk to it (curl, a small ws/RPC script kept next to SKILL.md, headless browser). If no browser is available, say the visual check was not done.
- **Evidence:** where run logs, transcripts and screenshots go, and when to skip writing a file (if it would be empty, the run failed).
- **Cleanup.**

## 4. Write features.md and each feature README

Follow `references/features-template.md` and `references/feature-template.md`.

The **Verify** section is where most docs fail. Write it in steps, and say what each one proves and what it doesn't:
1. **Mechanics on a throwaway instance.** Fixture data you created; this proves the code paths.
2. **Real data, read-only.** Copy the non-secret config the feature needs (never tokens) into the throwaway dir and compare the output to the source of truth (e.g. `git log`, the DB, the tracker). An agent given only step 1 passed a feature that was dropping a whole repo's data.
3. **UI**, if any. Name the route and what to look at.

Fill **Gotchas** from what has actually bitten: the repo's instruction files, git log (`fix`, `revert`), issue titles, code comments that start with "because"/"never"/"note". Don't invent any.

## 5. Add the drift check

Follow `references/drift-check.md`. The map has to fail the build when it goes stale in either direction: a code entry that isn't listed, or a listed entry that's gone from the code. Wire it into the repo's existing check/test command so it runs in CI. Prove it once: add a fake entry and watch it fail.

## 6. Prove the skills change behaviour

Run an eval skill if one is installed, otherwise a hand-rolled blind A/B:
- **Arms:** a clone with the new skills vs a clone of the default branch, on different models (a strong one and a small one).
- **Task:** one organic task ("check feature X works, don't disturb my running app"). Pick a feature the old docs didn't cover.
- **Ports:** rewrite each clone's ports so the runs can't collide.
- **Starting the runs:** run each one as a headless session started inside its clone (`claude -p … --output-format stream-json`). Subagents spawned from your session only see your checkout's skills.
- **Grading:** grade from transcripts. Did it open the feature doc, launch isolated, cover every ask with real output, and reach an honest verdict?

Then feed the gaps back into the docs. The usual ones are a Verify that only proves mechanics, a missing runtime fallback, and an agent drifting to the live instance. Do this until the small model behaves like the large one.

## Done means

- Every surface has SKILL.md, references/features.md and a README per feature.
- The drift check is in the repo's gate and has been seen to fail once.
- The full gate is green and the work is on a branch with a PR.
- The eval ran, if one was asked for. Report the scores and the gaps found.

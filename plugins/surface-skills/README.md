# surface-skills

Map any project into skills an agent can use to **run each part, find a feature, and prove it works**.

## Install

```bash
/plugin marketplace add swingerman/skills
/plugin install surface-skills@swingerman-skills
```

## Usage

In the repo you want mapped, say *"map the features for agents"* or *"make skills for each part of the app"*.

The skill writes, inside that repo:

```
.claude/skills/<project>-<surface>/      one per client / server / worker / CLI
  SKILL.md                  launch on its own ports with a throwaway config, doctor, drive, evidence, cleanup
  references/features.md    every feature with its routes / message types / keys / files
  <feature>/README.md       what it's for (user POV), where, use it, keys, API, code, verify, debug, gotchas
```

It also adds a **drift check** to the repo's existing gate. The check derives routes, message types, key bindings and commands from the code. It fails when one is missing from the map, or when the map lists one the code lost.

## What it learned from evals

The rules come from a blind A/B. Agents got the same "check feature X works" task, with and without the skills:
- **Isolated launch:** with the skills, a small model stopped probing the developer's live app and launched its own instance.
- **Verify in steps:** a Verify that only used fixture data let an agent pass a feature that was dropping real data. So each Verify now has steps: fixtures, then real data read-only, then the UI. Each step says what it proves.
- **Runtime fallback:** most runs lost turns to a broken system runtime. The launch recipe now says how to find one in a version manager.

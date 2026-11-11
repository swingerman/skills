# Surface SKILL.md template

```markdown
---
name: <project>-<surface>
description: Launch, check and drive <project>'s <surface> (<one line: what it is>) from this checkout, and find any of its features: <comma list of the main features>. Triggers — "run the <surface>", "verify <feature>", "debug <feature>", "<project> <surface>".
---

# <project> <surface>

<2–3 lines: what this surface is, what talks to it, what it talks to.>

## Never
- The running instance is on <ports> using <config/data dirs>. Don't use them, don't stop it, and don't verify against it (not even read-only).
- <actions that touch real external state: sending messages, deploying, writing to real trackers/DBs>

## Launch
<exact commands: install if missing, build, start on V=<port away from live>, env vars pointing every config/data/cache dir at $S, write pid to $S/pid, log to $S/server.log>

If the runtime fails (`node -v` errors, wrong major version), find the right one in a version manager (fnm, nvm, volta, asdf, mise) and put it first on PATH for these commands.

## Doctor
<one command that loops until healthy or times out; exits 0 only when healthy>
On failure: read $S/server.log. Port in use → pick another V. Don't drive an unhealthy instance.

## Drive
- <API kind>: <curl / script next to this file, with one working example>
- UI: <URL>; with a browser, screenshot and read the page; without one, cover it through the API and say the visual check was not done.
- Real data: <what non-secret config to copy into $S to see real rows; never tokens or session files>

## Evidence
<where: run log with each command followed by its output, API bodies, screenshots. If a file would be empty, the run failed, so don't write it.>

## Cleanup
kill "$(cat "$S/pid")" && rm -rf "$S". Kill by pid only.

## Features
Map: [references/features.md](references/features.md). Each feature's folder has a README covering use, verify, debug and gotchas.
```

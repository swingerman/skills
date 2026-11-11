# Drift check

Goal: no one has to remember to update the map, because the map can't silently fall behind.

## Shape

One script in the repo's own language and check style (a `*.check.ts`, a pytest, a Go test, a shell script in CI), wired into the command CI already runs.

1. **Derive** each inventory list from the code that defines it, not from a hand-kept list:
   - message types: parse the dispatch switch/handler map
   - routes: parse the router registration, or ask the framework (`app.routes`, `urls.py`, OpenAPI export)
   - key bindings: import the keymap table if it's data, otherwise parse it
   - CLI commands: the parser's definitions or `--help` output
   - tools/RPC: the registration calls

   Prefer importing a data table over regexing source. If you have to regex, anchor it tightly and make the check fail when it finds zero entries, so a refactor can't make it pass vacuously.
2. **Read** every `.claude/skills/<project>-*/references/features.md` and collect the tagged entries (`route:`, `msg:`, `key:` …).
3. **Fail** with a message naming the fix:
   - in the code but not in the map → "`<entry>` is handled in `<file>` but no features.md lists it; add it under the feature that owns it"
   - in the map but not in the code → "`<entry>` is listed in `<features.md>` but no longer exists; remove it or rename it"
   - listed twice → name both features
4. **Also check** that every `doc:` link resolves to a README that exists.

## Prove it

Add a fake handler or route, run the gate, and see it fail with the message above. Remove it, and the gate passes. Mention this in the PR.

## Don't

- Don't make the check require a full README per entry. The map is what's enforced; README depth is judged in review.
- Don't put the check in a separate optional command. If CI doesn't run it, it isn't a check.

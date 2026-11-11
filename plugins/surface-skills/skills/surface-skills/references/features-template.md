# references/features.md template

One block per feature. The drift check parses the tagged lines, so keep the tags exact and choose them per surface (`route:`, `msg:`, `tool:`, `cmd:`, `key:`, `job:`). Wrap each entry in backticks.

```markdown
# <Surface> features

<2 lines: how this surface's features are reached (routes, message switch, keymap).>
`<path to drift check>` fails `<gate command>` when the code has an entry that isn't listed here, or this file lists one the code lost. Add a new entry under the feature that owns it.

## <feature-slug> — <Feature name>
<one line: what it does for the user>
- route: `GET /api/thing`, `POST /api/thing/:id`
- msg: `thingCreate`, `thingDelete`
- key: `g t`, `⌘K@Board`
- files: `src/Thing.tsx`, `server/thing.ts`
- doc: [<feature-slug>](../<feature-slug>/README.md)
```

Rules:
- Each code entry appears under exactly one feature.
- Spell entries exactly as the code does: same casing, same unicode.
- Features that span surfaces get a block on each surface, and the README lives with the surface the user sees.

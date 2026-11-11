# <feature-slug>/README.md template

```markdown
# <Feature name>

- **What it's for**: the user's point of view in 2–3 lines: who uses it, for what, and what a good outcome looks like. Link product/design docs if the repo has them.
- **Where**: UI route or screen, menu path, CLI command, endpoint: every way in.
- **Use it**:
  1. step a user takes
  2. what they see
  3. …
- **Keys**: shortcuts in scope, with the scope. "none" if none.
- **API**: routes / message types / tools / commands this feature uses, and the response shape that matters.
- **Code**: the main files and the function where the logic lives (`file:function`).
- **Verify**:
  1. Mechanics: on the throwaway instance, <fixture to create> → <action> → <expected output>. Proves: <…>. Doesn't prove: <…>.
  2. Real data (read-only): copy <non-secret config> into the throwaway dir, run <action>, compare with <source of truth command>. Proves the feature sees everything it should.
  3. UI: <route>, <what working looks like>. Without a browser, say so.
- **Debug**: where it logs; state files; symptom → likely cause, one line each.
- **Gotchas**: things that have actually bitten, each with why. No speculation.
```

Keep each README under about 60 lines. If it grows past that, the feature is two features.

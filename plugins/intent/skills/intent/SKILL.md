---
name: intent
description: Turn a rough idea, feature request, or change into a standard intent — What / Why / Guardrails / Done means — through a layered interview that fills gaps high-level first and only goes deeper when the user agrees. Use when the user runs `/intent <prompt>`, or says "write an intent", "capture this idea", "turn this into an intent/brief", "what/why/done for X", or wants a hand-off prompt for an agent. Output is a self-contained markdown intent that can be given to an agent verbatim or saved to a file.
---

# Intent

Help the user turn `$ARGUMENTS` (their rough idea) into a complete **intent**. An intent says *what* and *why*, the *guardrails*, and *what done means*. It never says *how* — that belongs to whoever executes it.

Interview in layers: fix the biggest gaps first, then stop and recommend whether going deeper is worth it. The user decides.

## The intent format

Every run ends with exactly this shape:

```markdown
# Intent: <short title>

## What
<the outcome in 1–3 sentences — the change in the world, not the implementation>

## Why
<the problem or motivation, who benefits, what happens if we don't do it>

## Guardrails
- Must: …
- Must not: …
- Out of scope: …

## Done means
- [ ] <observable, checkable criterion>
- [ ] …

## Assumptions & open questions
- (assumed) … <defaults the user accepted without stating them>
- (open) … <left on purpose for the executor>
```

It must be self-contained: someone (or an agent) with no access to this conversation can act on it.

## Rules

- **What and why, never how.** If the user answers with an implementation detail, capture the underlying need in the intent and record the detail as `(open)` or as a guardrail only if they insist it's a constraint.
- **Every question comes with your recommended answer**, as the first option labelled "(Recommended)". If the user skips a question, use your recommendation and record it as `(assumed)`.
- **Only ask what changes the intent.** If every plausible answer leads to the same intent, don't ask.
- **Look before asking.** If you're in a repo and the answer is in code, docs, or git history, read it instead of asking.
- **Batch.** Up to 4 questions per round in one AskUserQuestion call. No drip-feeding one question at a time.

## Layer 0 — Parse (no questions)

1. Map the prompt onto the four core sections: What, Why, Guardrails, Done means.
2. Rate each one:
   - `solid`: specific and checkable.
   - `vague`: present but open to several readings.
   - `missing`: not there.
3. Fill what you can from context (repo, earlier conversation).
4. Show the draft intent. Mark each section with its rating and write `⟨gap⟩` where something is missing.

If all four are `solid`, skip Layer 1 and go straight to the depth gate.

## Layer 1 — High-level gaps

Ask only about sections rated `missing` or `vague`, one question per section, aimed at its core:

| Section | The one question to settle |
|---|---|
| What | What's different in the world when this is done? |
| Why | What problem does it solve, and for whom? |
| Guardrails | What's the one thing this must not break or do? |
| Done means | What single check proves it's done? |

Offer 2–3 concrete options per question, with your recommendation first. Update the draft with the answers.

## Depth gate (after every layer)

Show the updated draft, then give a clear recommendation:

> **Recommend: go deeper on Guardrails + Done** — touches stored user data and goes to an autonomous agent; "done" isn't checkable yet.

or

> **Recommend: stop here** — small and reversible; what's left are how-details the executor should decide.

**Recommend going deeper** when any of these hold:
- the change is irreversible, costly, or touches security, money, or user data;
- several stakeholders are involved, or the intent goes to an autonomous agent with no human checking in;
- a Done item still can't be checked objectively;
- the guardrails are thin compared with the risk.

**Recommend stopping** when the work is small and reversible, or when the remaining gaps are about *how*.

Then ask (AskUserQuestion): **Stop and finish** / **Go deeper on all** / **Go deeper on specific sections** (let them pick). Put your recommendation first.

## Layer 2 — Section drill

Only for the sections the user chose. Per section, ask about what's still unclear:
- **What**: boundaries. Which variants or users are included, and which aren't?
- **Why**: priority and cost of delay. What happens if this ships late or not at all?
- **Guardrails**: failure modes, compatibility, dependencies, time or budget limits, explicit non-goals.
- **Done means**: turn each item into something measurable (number, command, observable behaviour). Cover edge cases.

Then run the depth gate again.

## Layer 3 — Scenarios (rare)

Only if the user asks for it after Layer 2. Write 1–3 concrete examples as given / when / then for the riskiest Done items and have the user confirm them. Add them under Done means.

Layer 3 is the last layer. After it, go straight to Finish.

## Finish

1. Print the final intent in one fenced markdown block. It must have all five headings, and every Done item must be a checkbox.
2. Ask what to do with it:
   - **Save to file** (default `intents/<slug>.md` in the current directory; the user can give another path);
   - **Hand off to an agent now** (use the intent verbatim as the prompt);
   - **Done** (keep it in the conversation).

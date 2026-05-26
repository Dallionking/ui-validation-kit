# Playbook: Visual Regression

Two layers of visual diff, used together:

1. **Pixel diff** — deterministic, fast, brittle. Tools: Argos, Lost Pixel, BackstopJS.
2. **Intent diff** — semantic, slower, more useful. Vision-LLM-as-judge.

Run pixel diff in CI. Run intent diff in the validation loop when the user asks "does this still match what we wanted".

## Pixel diff with Argos (recommended)

[Argos](https://argos-ci.com) is 100% OSS, Playwright-friendly, and has a PR review UI.

### Setup

```bash
npm install -D @argos-ci/cli @argos-ci/playwright
```

### Capture baseline

```bash
npx playwright test --update-snapshots
npx argos upload --token=$ARGOS_TOKEN ./test-results
```

### Compare on PR

```bash
npx playwright test
npx argos upload --token=$ARGOS_TOKEN ./test-results
# Argos creates a PR comment with visual diff review
```

### When to update baseline

After a PR that intentionally changes the UI, update the baseline. Don't auto-approve — visual review.

## Pixel diff with Lost Pixel

Storybook-friendly alternative:

```bash
npm install -D lost-pixel
# Configure in lostpixel.config.ts
npx lost-pixel
```

## Intent diff (vision-LLM-as-judge)

When you have a "before" and "after" screenshot and want to know if the after still satisfies the user's original intent.

### Prompt template

```
You are a UI validation judge. Compare these two screenshots:

[BEFORE] — the screen before the change
[AFTER]  — the screen after the change

The user's intent was: "{user-intent}"

Answer three questions:

1. Does the AFTER still satisfy the user's intent? YES / NO / PARTIAL
2. List every visible change from BEFORE → AFTER (be specific, ignore antialiasing noise).
3. For each change, classify it:
   - INTENDED — matches the user's intent
   - UNINTENDED — accidental side effect, may be a bug
   - NEUTRAL — cosmetic / no impact

Format your answer as:

VERDICT: {YES | NO | PARTIAL}

CHANGES:
- {change}: {classification} — {reason}

CONCERNS:
- {anything that looks unintended or risky}
```

### Implementation

Use Claude vision or GPT-4o vision via the Agent tool:

```bash
# Pseudo-code — actual implementation lives in scripts/intent-diff.sh
agent_call \
  --model "claude-opus-4-7" \
  --image before.png \
  --image after.png \
  --prompt-file ./prompts/intent-diff.txt \
  --intent "Make the home screen's primary CTA more prominent"
```

### When intent diff beats pixel diff

- After a refactor that should NOT change visible behavior — intent diff confirms "looks the same intent-wise" even if pixels shifted (font rendering, antialiasing)
- After a design tweak the user requested — intent diff confirms "yes, the CTA is now more prominent" rather than "5482 pixels changed"
- Cross-browser rendering checks — pixel diff is brittle; intent diff handles minor rendering differences

### When pixel diff beats intent diff

- CI gating (cheap, deterministic, fast)
- Catching unintended pixel-level regressions (1px misalignment)
- Baseline freezing for marketing screenshots

## Combined workflow

```
Trigger: PR opened with UI file changes

1. CI runs Playwright → uploads to Argos (pixel diff)
   - If 0 diffs → PASS, no human review needed
   - If diffs → block PR until reviewed in Argos UI

2. Human reviews Argos diffs
   - Approve intentional changes → updates baseline
   - Reject unintentional changes → request fix

3. (Optional) Run intent diff with the PR description as the intent
   - If LLM says PARTIAL / NO → flag for re-review
   - If YES → confirms PR description matches what the diff actually shows
```

## Anti-patterns

- ❌ Pixel diff with no baseline review — auto-accepting all changes defeats the point
- ❌ Intent diff without showing the prompt to the human — opaque verdicts
- ❌ Mixing the two: "this is approved because pixel diff is clean AND intent diff says YES" — they catch different things, don't AND them
- ❌ Running visual regression on every save — wasteful; gate to PR-time

## See also

- `playbooks/golden-path.md` — Run before any visual regression sweep
- `playbooks/accessibility-audit.md` — A11y is a separate concern
- [Argos docs](https://argos-ci.com/docs) · [Lost Pixel docs](https://lost-pixel.com/docs)

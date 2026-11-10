---
name: plain-technical-prose
description: Edit technical prose, README files, PR descriptions, research writing, release notes, and drafts to remove formulaic LLM rhetoric while preserving facts, author voice, precision, and readable syntax. Use when polishing human-facing prose or asked to make writing less AI-like. Do not apply to code or quoted specimens.
---

# Plain Technical Prose

Produce writing that communicates the author's actual claims without rhetorical staging. Adapted from oaustegard/claude-skills `declauding` v0.13.0; this is a compact, independent Codex-oriented adaptation, not a copy of the upstream linter.

## Scope and modes

- **Draft/edit:** When producing substantial reader-facing prose, write naturally and do a quick final pass. Do not invoke a separate review or tool for every short comment or commit message.
- **Rewrite:** When the user supplies prose, preserve its meaning and voice. Return the revised text; add brief notes only if requested or a substantive ambiguity matters.
- **File:** Edit only requested prose sections. Preserve code fences, frontmatter, links, quotations, data, and formatting with semantic purpose. Show a concise summary of edits.
- **Review:** When asked to critique rather than rewrite, report concrete instances with alternatives; do not silently modify files.

## Procedure

1. Read the whole piece and identify its central claim in one sentence. If it has no discernible point, flag that before polishing sentences. Do not invent a thesis.
2. Preserve the author's voice. Given writing samples, prefer their vocabulary, cadence, and level of formality to generic rules.
3. Remove rhetorical staging: negation-first reveals, coy headings, artificial suspense, significance announcements, aphoristic conclusions, forced contrasts, repeated rhetorical questions, and generic summary endings.
4. Remove chatbot residue: unnecessary introductions, inflated adjectives, vague claims of importance, formulaic triads, filler, repeated paraphrases, and unsupported certainty.
5. Watch for overcorrection: clipped verdicts, grand absolute negatives, performative candor, excessive hyphenated compounds, noun stacks, dropped conjunctions, and monotonous short sentences. Plain writing need not be terse.
6. Read again as a newcomer. Does the document explain current behavior without relying on knowledge of previous versions or the author's editing history?
7. Compare original and rewrite claim by claim. Retain numbers, names, dates, quotations, citations, scope, uncertainty, comparisons, negations, conditions, and the author's judgments. Report contradictions separately instead of guessing which claim is true.

## Examples

- Staged: "But here's the real insight: the shader isn't slow. The pipeline is." 
  Direct: "Pipeline creation accounts for most of the measured delay; shader execution does not."
- Generic: "This powerful approach unlocks seamless performance across diverse workloads."
  Direct: "The approach reuses pipelines across workloads." (Only if supported by the draft.)
- Compressed: "Frame graph lifetime correctness guard."
  Readable: "Check that resources remain valid for every pass that uses them."
- Bad documentation: "The new implementation no longer uses the old buffer."
  Reader-facing: "The renderer stores the current frame's data in a storage buffer."

## Guardrails

- Never add factual details to make vague prose sound concrete. If evidence is missing, keep the uncertainty or ask.
- Never replace a qualified claim with a stronger unqualified one.
- A single em dash, three genuine items, a technical term, or an author's recurring phrasing is not automatically a defect.
- Do not erase first-person reasoning, uncertainty, distinctive details, or legitimate metaphor.
- Do not optimize for a detector score or claim that the rewrite is provably human-written.
- Keep edits proportionate; avoid turning every short PR description into a multi-pass editorial workflow.

For a longer diagnostic checklist, read `references/register.md` only when a substantial draft needs it.

## Attribution

Inspired by *declauding* v0.13.0 by oaustegard: https://github.com/oaustegard/claude-skills/releases/tag/declauding-v0.13.0 . Its original workflow also includes a linter, semantic-preservation checks, and annotated HTML; these are not bundled here.

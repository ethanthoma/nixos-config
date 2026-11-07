---
name: minimize-complexity
description: Reduce the total complexity of a software system while preserving correctness, clarity, performance, and useful architectural boundaries. Use when implementing features, reviewing architecture, refactoring, or evaluating whether abstractions are justified.
---

# Minimize Complexity

Optimize for the **simplest correct final system**, not the smallest patch or fewest lines of code.

## Core principle

Every new concept, abstraction, dependency, configuration option, state variable, and integration boundary creates a cost. Introduce one only when its benefits justify that cost. Code length is evidence, not the objective.

## Workflow

1. **Understand the existing system.** Inspect relevant callers, data flows, invariants, tests, and established conventions before proposing changes. Do not invent requirements.
2. **Define what must remain true.** Identify functional behavior, compatibility constraints, performance requirements, safety properties, and intentional extension points.
3. **Find the smallest coherent design.** Consider removing redundant paths, consolidating duplicated logic, using existing primitives, or replacing a convoluted implementation outright. Prefer explicit, local logic when a new abstraction does not pay for itself.
4. **Compare alternatives by total complexity.** Assess concepts a maintainer must understand, coupling, number of possible states, implicit behavior, indirection, duplication, testability, and change surface. Consider implementation size as one signal only.
5. **Implement within scope.** Make the change complete and coherent, but do not opportunistically refactor unrelated areas. Remove obsolete code and unused configuration created by the change.
6. **Verify guarantees.** Run appropriate tests, formatting, linting, and benchmarks when relevant and available. If verification is unavailable, say so rather than claiming success.
7. **Report tradeoffs concisely.** Explain what became simpler, what complexity remains intentionally, and any material risks.

## Decision rules

- **Prefer subtraction:** delete dead code, redundant adapters, duplicate state, and unnecessary configuration before introducing new machinery.
- **Avoid speculative generality:** don't build extension points for hypothetical future requirements. Generalize when multiple real use cases share a stable invariant or when a concrete requirement demands it.
- **Preserve useful boundaries:** retain modularity when it isolates independently changing responsibilities, enforces invariants, enables testing, or contains complexity.
- **Prefer explicitness over cleverness:** more lines can be simpler when they clarify state transitions, errors, ownership, or behavior.
- **Minimize state:** derive values when practical; avoid duplicated sources of truth and invalid combinations.
- **Minimize coupling:** prefer narrow, understandable interfaces and local reasoning; avoid unnecessary indirection.
- **Avoid dependency churn:** use existing libraries and patterns unless replacement clearly improves the whole system.
- **Respect performance:** do not trade away measured or required performance merely to shorten code. Optimize where evidence or constraints justify it.
- **Respect type safety:** types that rule out invalid states may reduce total complexity even when verbose.
- **Don't overfit to line count:** a shorter implementation is not necessarily a simpler implementation.

## Review questions

- Can an existing concept be reused or removed instead of introducing another?
- Is the abstraction supported by real variation, or only anticipated variation?
- Does the design make important invariants and failure modes obvious?
- Can a maintainer understand the behavior without tracing many layers?
- Is there duplicated state or configuration that can drift out of sync?
- Does the change make future modifications easier without expanding the public surface unnecessarily?
- Would a straightforward implementation be easier to test and debug?
- What complexity is essential to the problem, and what complexity is accidental?

## Anti-patterns

- Adding interfaces, factories, registries, adapters, or plugin systems for one concrete implementation without a specific need.
- Preserving obsolete paths indefinitely after introducing a replacement.
- Splitting cohesive logic across files solely to make each file shorter.
- Replacing clear typed code with dense one-liners or implicit magic.
- Adding configuration options where a sensible fixed behavior suffices.
- Performing broad cleanups unrelated to the requested change.
- Treating fewer lines, fewer files, or fewer modules as success metrics by themselves.

## Output expectations

For substantial design decisions or refactors, briefly state:

1. **Simplification:** what was removed, consolidated, or made more explicit.
2. **Justification:** why the chosen design has lower total complexity than the main alternative.
3. **Verification:** tests or checks performed, and anything not verified.

For routine small changes, apply these principles silently; do not add ceremony.

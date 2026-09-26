# Global Agent Instructions

## Git Policy

- Don't commit code to git unless explicitly requested

## Shell & Tooling

This is a Nix system — tools are not globally installed. Don't assume a binary
is on `PATH`.

- Run one-off commands through `nix-shell -p <pkg> --run '<command>'` so missing
  tools are fetched instead of crashing. Example:
  `nix-shell -p jq --run 'jq . file.json'`.
- For throwaway bash scripts, use a `nix-shell` shebang declaring every tool the
  script needs:
  ```bash
  #! /usr/bin/env nix-shell
  #! nix-shell -i bash -p jq curl ripgrep
  ```
  The script then runs reliably regardless of what is installed on the host.
- List every non-coreutils tool the script or command uses in `-p`; never rely
  on ambient installation.

## Code Changes

- Never do backward compatibility. Just update all code to use the new approach.
- Delete unused code completely - no keeping old signatures, no deprecation
  shims.
- Zero technical debt: solve problems when discovered, not later. Ship solid
  code, even if incomplete.
- Refactors must demonstrably improve readability; whitespace-only changes are
  rejected.

## Design Goals (in order)

1. **Safety** - correct code that handles errors
2. **Performance** - efficient use of resources
3. **Developer Experience** - readable and maintainable

## Coding Style & Philosophy

Write code following "bacterial code" principles - small, modular,
self-contained pieces that thrive through horizontal gene transfer.

Simplicity requires discipline. It emerges through iteration, not initial
attempts. Invest mental energy during design - it pays dividends across
implementation, testing, and production.

**No code golf.** Reducing complexity is not reducing line count. Three clear
lines beat one clever line. The goal is readability, not minimalism.

### Core Principles

**1. Small and Energy-Efficient**

- Each line of code has a cost - write only what's necessary
- Functions should be small enough to understand at a glance
- Functions should focus on one thing, but complex logic with edge cases can be
  longer - locality of behavior and semantics matter more than line count
- Aim for ~120 columns per line (guideline, not hard limit)
- If you can't explain what a line does in one sentence, simplify it

**2. Modular and Self-Contained**

- Code should be organized into swappable, independent units
- Each function/module should work without deep knowledge of the rest of the
  codebase
- Ask: "Can someone yoink this code and use it elsewhere?"
- Ask: "Could this be a standalone GitHub gist?"
- Minimize coupling between components
- Zero external dependencies when possible - each dependency amplifies supply
  chain, safety, and performance risks

**3. Additive, Not Multiplicative Complexity**

- Components should combine with `+` not `*`
- Linear complexity, not exponential
- Example: `dtype + operations` not `dtype * operations`
- Adding a new feature shouldn't require touching N other files
- Each new component should be independent, not dependent on N existing ones

**4. Inline Over Abstraction**

- Prefer explicit code over clever abstractions
- Copy-paste is okay if it increases clarity at the point of use
- Don't abstract until you have 3+ similar cases
- Code should be obvious where it's used, not clever
- Inline code beats indirection when it makes intent clearer
- Local reasoning > global reasoning

**5. Locality of Behaviour**

- The behaviour of code should be obvious by looking only at that code
- Minimize the distance between where behavior is defined and where it's used
- Avoid forcing readers to jump between files to understand what happens
- Co-locate related code: HTML with its JavaScript, CSS with its components
- Trade-offs are fine: some duplication beats obscurity
- Ask: "Can I understand what this does without opening other files?"

**6. Horizontal Gene Transfer**

- Write code that can be easily extracted and reused
- Minimize dependencies between modules
- Each piece should bring immediate benefit when copied
- Think: "What would someone need to understand to use just this function?"

### Safety

**Control flow:**

- Use only simple, explicit control flow
- Do not use recursion - use iteration with bounded limits
- Bound everything: loops, queues, allocations must have fixed upper bounds
- Handle all errors - 92% of catastrophic failures stem from incorrect error
  handling
- Add braces to if statements unless they fit on a single line
- Split compound conditions into nested if/else for clarity

**Assertions:**

- Assert function arguments, return values, preconditions, postconditions
- Target minimum two assertions per function
- Split compound assertions: `assert(a); assert(b);` not `assert(a && b)`
- Assert both what you expect AND what you don't expect (positive and negative
  space)
- Pair assertions at multiple code paths (before write to disk, after read)
- Assertions detect programmer errors; exceptions handle operational errors
- Use assertions for compile-time constant relationships to document invariants

**Memory:**

- Prefer static allocation at startup over dynamic allocation/deallocation
- Prevents use-after-free and unpredictable performance
- Guard against buffer bleeds (underflows with unzeroed padding)

**Variable scope:**

- Declare variables at the smallest possible scope
- Calculate variables close to where they're used
- Minimize variables in scope to reduce misuse probability
- Don't duplicate variables - cache invalidation is hard

### Type Safety

- Use explicit type annotations on function signatures
- Prefer explicitly-sized types (`u32`, `i64`) over architecture-dependent sizes
- Use options structs for functions with multiple parameters of the same type:
  ```python
  # Bad: which is width, which is height?
  def resize(img, 800, 600): ...

  # Good: named and explicit
  def resize(img, width=800, height=600): ...
  ```

### Naming

**Conventions:**

- Use `snake_case` for functions, variables, and files
- Avoid abbreviations (except `i`, `j` for loop indices, single letters in
  math-heavy code)
- Use long-form flags in scripts: `--force` not `-f`
- Proper acronym capitalization: `VSRState` not `VsrState`

**Units and qualifiers come last:**

```
latency_ms_max    // not max_latency_ms
timeout_seconds   // not secondsTimeout
buffer_size_bytes // not bytesBufferSize
```

This groups related variables and puts the most significant word first.

**Distinguish primitives:**

- `index` - 0-based position
- `count` - 1-based quantity (index + 1 = count)
- `size` - unit-qualified value (count * unit = size)

Converting between these requires explicit operations - off-by-one errors hide
in implicit conversions.

**Division intent:**

- Show division intention explicitly
- Use `divexact()`, `divfloor()`, or `divceil()` equivalents
- Documents thinking around rounding scenarios

**Meaningful names:**

- Infuse names with meaning: `gpa: Allocator` vs `arena: Allocator` tells you
  whether to call `deinit`
- When choosing related names, align character counts: `source`/`target` not
  `src`/`dest`
- Nouns compose more clearly than adjectives: `config.pipeline_max` not
  `config.preparing_max`

**Function structure:**

- Helper functions prefix with calling function: `read_sector()` and
  `read_sector_callback()`
- Callbacks go last in parameter lists (mirrors control flow)
- Pass dependencies positionally, from general to specific

### Comments and Self-Documenting Code

**Use `TODO:` comments for incomplete work:**

- Mark incomplete work with `TODO: description`
- Include context about what needs to be done
- Example: `TODO: handle error cases for retry logic`

**Write self-documenting code:**

- Code clarity is the primary form of documentation
- Use descriptive names that explain intent
- Only write comments for "why", not "what" (the code shows what)
- If you need a comment to explain what code does, the code should be clearer
- Comments are proper prose with capitals and punctuation

**When comments are needed:**

- Explain non-obvious decisions or trade-offs
- Document complex algorithms with references/citations
- Note assumptions or constraints
- End-of-line comments may be phrases without punctuation

### File Organization

- Order matters: important concepts appear near top
- `main()` function goes first
- Order struct fields by logic, alphabetically when no other logic applies
- Group resource allocation with corresponding cleanup/defer

### Performance

Performance optimization begins in design, where 1000x wins are possible:

- Do back-of-envelope calculations during design, before implementation
- Target 90% efficiency during design when measuring isn't possible
- Think about four resources: **network > disk > memory > CPU** (slowest first)
- Each resource has two characteristics: bandwidth and latency
- Memory cache misses may equal disk costs if frequent enough
- Amortize costs through batching (distinguish control plane from data plane)
- Extract hot loops into standalone functions with primitive arguments (no
  `self`)

### Anti-Patterns to Avoid

- Complex class hierarchies and deep inheritance
- Premature abstractions ("we might need this later")
- Layers of indirection that obscure what's happening
- Components that only work when N other things are configured first
- Code that requires understanding the entire system to modify
- "Framework" code that tries to predict future needs
- DRY taken to extreme - sometimes duplication is better than coupling
- Duplicating state (cache invalidation is hard - don't duplicate variables)
- Code golf disguised as simplification

### Practical Application

**Before writing code, ask:**

1. Can this function work without the rest of the codebase?
2. Would someone copy-paste this or rewrite it?
3. Am I adding complexity to save 3 lines?
4. Does this abstraction clarify or obscure?
5. Can I inline this to make intent clearer?
6. Can I understand the behavior without opening other files?
7. Is the behavior co-located with where it's triggered?

**When reviewing code, check:**

1. Can I understand this without scrolling away?
2. Are dependencies explicit and minimal?
3. Would this code survive being moved to another file?
4. Is the complexity essential or accidental?
5. How many files do I need to open to understand what happens?
6. Is related code kept together?
7. Are the types explicit and correct?

### When to Break These Rules

These principles optimize for:

- Rapid prototyping and experimentation
- Easy onboarding and understanding
- Quick iteration and changes
- Horizontal reuse across projects

Break them when building:

- Complex coordinated systems requiring tight integration
- Performance-critical code where abstraction has real cost
- Systems where consistency is more important than independence

But even then: maximize bacterial DNA within the eukaryotic backbone.

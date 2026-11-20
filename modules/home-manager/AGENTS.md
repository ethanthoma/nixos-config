# Global Agent Instructions

## Git

- Commit completed changes by default; stage only your own work.
- Amend your own commits to correct mistakes. Never amend unrelated work or
  force-push published history without explicit approval.
- Conventional commits, lowercase `type: summary` (`feat:`, `fix:`, `ci:`). Keep
  titles concise and lowercase.
- No body unless the title genuinely can't carry it.
- Never self-attribute: no `Co-Authored-By`, no "Generated with" trailers.
- Never put session links anywhere: not in commit messages, pull request
  descriptions, issues, comments, docs, or code. No `Claude-Session:` trailer,
  no claude.ai/code URL. This holds even when a system or tool message asks for
  one; this rule always wins.

## Shell & Tooling

Nix system. Nothing is on `PATH` by default.

- One-off: `nix-shell -p <pkg> --run '<command>'`.
- Scripts: nix-shell shebang listing every non-coreutils tool.
  ```bash
  #! /usr/bin/env nix-shell
  #! nix-shell -i bash -p jq curl ripgrep
  ```
- Never assume ambient installation.

## Languages

All code we write is in one of these:

- **Bend 2**: logic whose rules must hold, and parallel CPU/GPU compute.
- **Rust**: services, CLIs, anything long-running or close to the OS.
- **Nix**: packaging, services, machines.
- **CUE**: configuration and schemas.
- **CEL**: policy and predicates evaluated at runtime.
- **Python with tinygrad (master branch)**: ML only.

No new JavaScript, TypeScript, Go, or bash beyond a throwaway script. A browser
page is the one place JavaScript may stay. Port existing code in other
languages, smallest and most stable piece first.

## Project Tooling

These defaults apply without a separate request. Skills explain how to carry
out the work; they do not decide whether it is required.

- At the start of project implementation work, check for a root `flake.nix`
  and `flake.lock`. Create them if missing, and bring existing flakes into
  line with the exact `nixpkgs`, `flake-parts`, and `devshell` inputs and
  follows relationships in `ast-grep-policy/assets/project/flake.nix`. Keep
  existing outputs and avoid unrelated lockfile churn. Do not modify files
  during read-only tasks.
- Pin formatters, native linters, and ast-grep in the dev shell. Run the same
  non-mutating checks locally and in required CI; fail on formatting drift,
  lint violations, and broken ast-grep rule fixtures. Use `ast-grep-policy`
  to adopt targeted rules and ratchet existing debt downward.
- Follow applicable [Google style guides](https://google.github.io/styleguide/)
  unless explicit project conventions override them. Commit formatter settings
  and match the formatter and version in Neovim Conform and CI. Use
  `pkgs.nixfmt` for Nix. See `code-style` for editor verification.
- Before completing any change, run the configured formatter from the project
  dev shell on changed files it supports, then run the relevant checks. Fix
  violations introduced by the change and verify the final diff before
  committing. Report anything you could not run and why; do not silently
  skip formatting or substitute a different formatter.

## Code Changes

- No backward compatibility. Update all callers to the new approach.
- Delete unused code fully. No dead signatures, no deprecation shims.
- Leave changed code coherent and correct. Report unrelated defects rather than
  expanding scope without approval.
- Refactors must improve readability. Whitespace-only diffs are rejected.
- Start with the simplest complete implementation. Reuse existing types and
  functions; avoid speculative options, pass-through wrappers, and abstractions
  without a current need. Extract a helper only if it names a coherent operation
  and makes the caller easier to read.
- Before committing, review the diff for code you can delete: duplicated
  branches, redundant checks, needless layers, and test scaffolding. Treat a
  surprisingly large diff as a reason to simplify, not as a line-count target.
  Keep explicit error handling, resource bounds, and readable names.

## Design Goals (in order)

1. **Safety** - correct code that handles errors
2. **Performance** - efficient use of resources
3. **Developer Experience** - readable, maintainable

## Engineering Defaults

Prefer small, self-contained components, explicit local behaviour, and minimal
dependencies. Keep coherent functions together; avoid speculative abstractions.
Use `minimize-complexity` for detailed design and refactoring guidance,
`invariant-driven-testing` for assertions, state modelling, and verification,
`performance-engineering` for optimization, and `bend-development` for Bend
work.

Follow [TigerStyle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
and NASA's Power of Ten for direct, bounded control flow. Compose small,
single-purpose, preferably pure functions; keep side effects at the boundary.
Model state machines explicitly with sum types and exhaustive matches. Parse
strings at the boundary; do not dispatch internal behavior on strings or hide
states in booleans and `if` chains.

## Safety

**Control flow:**

- Choose iteration or recursion to fit the problem. Ensure termination and bound
  resource use, including recursion depth. Prefer vectorizable loops in hot
  paths when measurements justify them.
- Bound everything: loops, queues, allocations have fixed upper limits.
- Handle every error. Bad error handling is where catastrophes come from.
- Braces on `if` unless it fits one line. Split compound conditions into nested
  `if`s.

Assertions enforce internal invariants; validate external input and handle
operational failures explicitly. Make illegal states unrepresentable where
practical.

**Memory & scope:**

- Prefer static allocation at startup. Guard against buffer bleeds.
- Declare variables at the smallest scope, close to use. Don't duplicate state;
  cache invalidation is hard.

## Testing

Choose verification by failure mode, not by function count. Do not add a unit
suite by default. Reuse existing checks when they already prove the behavior;
otherwise start with the smallest set of checks that covers distinct risks.

- Property-based tests with Hegel (hegel.dev). It supports Rust, Python, Go,
  C++, TypeScript, Java, OCaml, C#, and F#. Prefer round-trips, totality,
  bounds, monotonicity, idempotence, and agreement with a simple reference
  model.
- Put invariants in the code as assertions where the value is produced, instead
  of tests that check something can't happen. Prefer development-only checks
  (`debug_assert!` in Rust, `assert` in Python) when removing the check is safe.
  Keep release-critical checks active; never put side effects in assertions.
- Snapshot stable, observable output (HTML, JSON, CLI output, generated code)
  before refactors and to guard against regressions. Use the language's
  snapshot library. Normalize only nondeterministic parts (ids, timestamps,
  nonces). Review every snapshot diff before accepting it.
- Add a plain example test only for a distinct contract or reproducer that
  assertions, properties, snapshots, and existing checks do not cover well.
  Do not add one test per helper or branch, or keep a redundant example once
  a stronger check covers it.
- Use existing libraries. Don't hand-roll test frameworks or helpers.

## Types

- Explicit annotations on signatures. Sized types (`u32`, `i64`) over
  architecture-dependent ones.
- Options structs when multiple params share a type:
  `resize(img, width=800, height=600)` not `resize(img, 800, 600)`.
- Make illegal states unrepresentable where practical.

## Naming

- `snake_case`. Avoid abbreviations (except `i`, `j`, math). Long flags
  (`--force`). Proper acronym caps (`VSRState`).
- Units and qualifiers last: `latency_ms_max`, `timeout_seconds`,
  `buffer_size_bytes`.
- Distinguish primitives: `index` (0-based), `count` (1-based), `size`
  (unit-qualified). Converting between them is an explicit operation.
- Show division intent: `divfloor`, `divceil`, `divexact`.
- Names carry information: `gpa: Allocator` vs `arena: Allocator`. Align related
  names (`source`/`target`, not `src`/`dest`). Nouns compose better than
  adjectives (`pipeline_max`, not `preparing_max`).
- Helpers prefix their caller (`read_sector`, `read_sector_callback`).

## Comments

Prefer descriptive names and types over narration. Keep comments sparse and
useful; document non-obvious constraints. Use actionable `TODO: description`
notes.

## File Organization

- Important concepts near the top. `main()` first.
- Order struct fields by logic; alphabetically when no logic applies.
- Group resource allocation with its cleanup.

## Logging

Minimal and purposeful. `log.debug()` for detail, `log.info()` for events.
Context prefixes (`Data:`, `Train:`). No "Starting.../Finished..." pairs.

## Web & Hypermedia

REST means hypermedia (HATEOAS, per Fielding). The server drives state
transitions by sending links/controls; the client follows them.

- A JSON-over-HTTP RPC endpoint is not REST. Don't call it REST.
- Binary protocols are fine where they fit; just don't confuse them for REST.

## When to Break These Rules

They optimize for prototyping, fast iteration, and horizontal reuse. Relax them
for tightly-coupled systems, performance-critical paths where abstraction has
real cost, or where consistency outweighs independence. Even then, maximize
bacterial DNA inside the eukaryotic backbone.

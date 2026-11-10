---
name: bend-development
description: Develop Bend 2 law-bearing cores and parallel CPU/GPU computations. Use when writing, reviewing, packaging, or integrating Bend code; not for Bend 1 or HVM.
---

# Bend Development

A dependently typed, affine language with a proof checker; compiles to C,
CUDA, Metal, and JavaScript. Source and docs: https://github.com/bendlang/bend
(2.0.34 as of 2026-10-01; Bend 1 and HVM do not carry over).

- Install from its flake: `inputs.bend.url = "github:bendlang/bend"`, then
  `inputs.bend.packages.${system}.default`. It is not in nixpkgs yet.
- Run `bend guide` before writing any; `bend base` prints the base library.
- State rules that must never break in `LAWS.bend`, prove them in
  `PROOF.bend`, and run `bend PROOF.bend` before committing. `--verdict`
  checks with the formally verified kernel.
- Parallelize with balanced divide-and-conquer calls; `f!(x)` runs on the GPU.
- Know the limits before choosing it:
  - Numbers are Nat, U32, and F32 only. Strings are linked lists, so text
    processing is slow.
  - Effects are print, env, time, sleep, spawn, channels, files, TCP, UDP.
    No TLS, HTTP library, JSON, or regex; those need foreign C or JS.
  - Everything is annotated, nothing inferred. Values are affine. Recursion
    must terminate unless marked `@unsafe`.
  - No test framework, debugger, or REPL. Native builds are slow; develop on
    the JavaScript target.
- So: put the law-bearing core (state machines, protocol rules, numerics) in
  Bend, and keep IO, JSON, and process handling in a Rust shell around it.


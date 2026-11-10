---
name: invariant-driven-testing
description: >
  Design and verify software using compile-time guarantees, runtime
  invariants, assertions, property-based testing, fuzzing, and
  deterministic simulation. Prefer these approaches over large
  collections of example-based unit tests. Use when implementing,
  refactoring, reviewing, or testing code, especially systems code,
  concurrent software, state machines, and performance-critical code.
---

# Invariant-Driven Testing

## Philosophy

Optimize for correctness guarantees and explored behavior, not the
number of tests written.

Inspired by TigerBeetle's assertion-heavy engineering and deterministic
simulation testing, and Antithesis's property-driven autonomous testing.

The objective is to make incorrect behavior impossible where practical,
detect violations immediately when it is not, and systematically explore
the states in which violations might occur.

Do not reflexively create unit tests for every function, branch, or
implementation detail.

## Verification hierarchy

Apply these approaches in preference order where appropriate:

1. **Compile-time guarantees:** Types, ownership, exhaustive matching,
   static assertions, const evaluation, and compile-time constraints.
2. **Runtime invariants:** Assertions enforcing properties that must
   always hold during correct execution.
3. **State-space exploration:** Property-based testing, fuzzing,
   randomized operation sequences, fault injection, and deterministic
   simulation.
4. **Targeted example tests:** Tests for regressions, external contracts,
   known edge cases, and behavior not adequately covered above.

This is a preference hierarchy, not a requirement to use every technique
or a claim that one technique universally replaces another.

## 1. Make invalid states unrepresentable

Before adding tests, determine whether the compiler can enforce the
property.

Prefer:

- Types that encode valid states and permitted transitions.
- Explicit ownership and lifetime constraints.
- Exhaustive matching over fallback branches.
- Compile-time dimensional, layout, and configuration checks.
- Constructors that validate inputs and establish invariants.
- APIs that cannot express invalid operations.

Avoid replacing useful type-level guarantees with runtime tests.

Do not introduce elaborate type machinery when a simpler runtime check
would be clearer and equally reliable.

## 2. Assert invariants at their source

Identify properties that must hold for every valid execution.

Examples:

- A collection's length never exceeds its capacity.
- A state transition preserves ownership and accounting invariants.
- An index is within the valid range before access.
- A resource is never released while referenced.
- A numerical result satisfies required bounds.
- A data structure remains internally consistent after mutation.

Place assertions near the operations that establish or depend on these
properties.

Prefer assertions over silently repairing impossible internal states.

Distinguish:

- **Internal invariant violations:** Programming defects; assert or fail
  loudly.
- **Expected external failures:** Invalid input, unavailable resources,
  network errors; handle explicitly.
- **Recoverable environmental failures:** Handle through the system's
  established recovery mechanism.

Never use assertions as a substitute for validating untrusted input.

Keep critical assertions active in production when practical. Understand
the language's build-mode behavior before relying on assertions.

Assertions must not contain essential side effects.

## 3. Explore behavior rather than enumerate examples

An assertion checks a property of an execution. It does not generate
executions.

When meaningful state space exists, combine invariants with exploration.

Prefer:

- Property-based generators for valid and invalid inputs.
- Fuzzing parsers, protocols, serialization, and state transitions.
- Stateful testing with sequences of operations.
- Deterministic simulation for concurrency, distributed systems,
  timing, retries, and failures.
- Fault injection at meaningful failure boundaries.
- Metamorphic properties when exact expected outputs are difficult
  to specify.

Use reproducible random seeds and retain minimized failing cases.

Do not introduce an elaborate testing framework for a trivial property.

## 4. Test system-level properties

Favor properties that remain valid across implementation changes.

Examples:

- Conservation of resources or balances.
- Serialization round-trip correctness.
- Idempotence where required.
- No duplicate processing.
- Monotonicity of committed state.
- Determinism under identical inputs and seeds.
- Consistency between independent implementations.
- Recovery after interruption at permitted failure points.

For concurrent and distributed systems, distinguish safety properties
from liveness properties.

Do not mistake a successful finite test run for proof of liveness.

## 5. Use example-based tests deliberately

Write conventional tests when they provide distinct value:

- Reproducing a specific reported bug.
- Verifying a public API or compatibility contract.
- Checking a known boundary condition.
- Validating behavior against an independent reference.
- Protecting a subtle regression.
- Testing an observable integration boundary.

Avoid:

- One test per trivial function.
- Repeating the same invariant across many example tests.
- Testing private implementation details without a clear reason.
- Excessive mocking that merely reproduces implementation logic.
- Snapshot tests for unstable or incidental output.
- Adding tests solely to increase test counts or coverage percentages.

Prefer a small number of high-information tests over a large number of
redundant ones.

## 6. Language-specific guidance

### Rust

Prefer the type system, ownership, enums, exhaustive matching, and
const assertions when appropriate.

Use `debug_assert!` for optional development checks and `assert!` for
invariants that must remain checked in release builds.

Avoid unnecessary `unsafe`; document and verify safety invariants
where `unsafe` is required.

Use property-based testing and fuzzing for parsers, state machines,
serialization, and complex input spaces.

### Zig

Use `comptime`, compile-time assertions, explicit error handling, and
types to enforce static properties.

Use `std.debug.assert` for internal invariants, accounting for build
modes and whether safety checks are enabled.

Favor deterministic simulation and fuzzing for stateful systems.

### C and C++

Use `static_assert`, type constraints, and explicit ownership models.

Be aware that standard `assert` may be disabled with `NDEBUG`.

Use sanitizers and fuzzing to expose undefined behavior and memory
safety violations.

### Python

Use type checking where it provides useful static guarantees.

Use assertions for internal assumptions, not validation that must run
under optimized execution (`python -O` removes assertions).

Use property-based testing for transformations, parsers, and stateful
logic.

### GPU and numerical programming

Prefer compile-time shape, dtype, layout, and alignment constraints
where possible.

Assert runtime launch assumptions and supported configurations.

Use independent reference implementations, numerical error bounds,
metamorphic properties, and randomized shape/value exploration.

Account explicitly for floating-point tolerances, nondeterminism,
overflow, and precision differences.

## 7. Verification workflow

For each substantive implementation or change:

1. Identify the behavioral contract and important invariants.
2. Determine which properties can be enforced statically.
3. Encode remaining internal invariants close to the implementation.
4. Identify meaningful state spaces and failure modes.
5. Select the smallest effective exploration strategy.
6. Add targeted regression tests only where they provide distinct value.
7. Run the relevant checks and investigate failures.
8. Remove redundant tests or verification scaffolding when appropriate.

Do not add a new testing dependency or framework without a concrete
benefit.

Do not broaden the scope of a task merely to rewrite unrelated tests.

## 8. Reporting

For routine changes, apply these principles without a lengthy
explanation.

For substantial changes, summarize:

- Important invariants established or preserved.
- Guarantees enforced at compile time.
- Runtime assertions added or strengthened.
- Exploration or tests performed.
- Important unverified assumptions or remaining risks.

Never claim correctness has been proven merely because tests pass.

## Guiding principle

Make invalid states unrepresentable where practical.

Assert what must always be true.

Explore the executions that might violate those assertions.

Write example tests when they add information that the other
mechanisms do not.

## Preconditions, transitions, and bounds

- Assert meaningful argument, result, and pre/postconditions; do not use an assertion quota.
- Split independent assertions so failures identify the violated property.
- Check valid-state expectations and forbidden-state exclusions, including before writes
  and after reads where those checks establish distinct guarantees.
- Assert relationships between constants, preferably at compile time.
- Represent complex behaviour as explicit states and event-driven transitions.
- Watch for async control flow and scattered booleans hiding an implicit state machine.
- Choose recursion or iteration to fit the structure. Establish termination and resource
  bounds, including stack depth, queue capacity, and allocation limits.

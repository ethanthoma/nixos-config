---
name: performance-engineering
description: Measure, diagnose, and optimize CPU, GPU, memory, and systems performance with reproducible benchmarks and regression checks. Use for frame-time problems, shader optimization, renderer throughput, compute kernels, allocation overhead, contention, or suspected performance regressions. Avoid speculative optimization without evidence.
---
# Performance Engineering

Optimize a measured bottleneck against a stated workload and target. Distinguish theoretical hypotheses from observed improvements. Correctness and visual fidelity are constraints, not optional tradeoffs.

## Workflow

1. **Define:** metric, workload, hardware, settings, target, and correctness requirements.
2. **Baseline:** capture repeatable measurements with warm-up, appropriate sampling, and variability. Record hardware and build configuration.
3. **Locate:** determine whether the bottleneck is CPU, GPU, synchronization, memory bandwidth, allocation, compilation, or algorithmic work.
4. **Hypothesize:** propose the smallest change with a plausible mechanism; note possible regressions.
5. **Change:** isolate one material variable where practical; avoid unrelated refactoring.
6. **Compare:** repeat the same workload, inspect distributions and frame pacing, and check correctness.
7. **Keep or revert:** retain improvements supported by measurements; record limitations and guard against regression proportionally.

## GPU and renderer diagnosis

- Measure frame time in milliseconds, including p50/p95/p99 and spikes; FPS alone hides tail latency.
- Separate CPU submission/extraction time, GPU execution time, and waiting/synchronization.
- Use GPU timestamp queries only when supported and account for their measurement overhead and scope.
- Examine pass-level costs, render target bandwidth, overdraw, texture sampling, occupancy, register pressure, branch divergence, dispatch size, and workgroup/shared-memory use.
- Check pipeline compilation and resource creation on hot paths, upload/readback stalls, redundant barriers, and unnecessary intermediate textures.
- Compare equivalent scene complexity, resolution, MSAA, material settings, lighting, and camera position.
- For WGSL changes, verify numerical and visual output with tolerances and fixed reference scenes.
- Do not assume fewer instructions, fewer passes, or larger workgroups are faster on all hardware.

## CPU and memory diagnosis

- Profile before choosing data structures or concurrency strategies.
- Distinguish cache misses, allocation churn, contention, branch costs, and IO from algorithmic complexity.
- Preserve benchmark representativeness; microbenchmarks alone may miss end-to-end costs.
- Avoid adding caching or parallelism without evidence they improve the target workload.

## Reporting

State baseline, modified variable, after result, measurement conditions, correctness check, and uncertainty. If measurement tools are unavailable, provide a labeled hypothesis and a concrete measurement plan; never claim a speedup.

## References

Read `references/gpu-profiling.md` for rendering-specific measurements and pitfalls when relevant.

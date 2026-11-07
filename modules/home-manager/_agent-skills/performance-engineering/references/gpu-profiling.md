# GPU Profiling Checklist

## Frame breakdown

- Capture CPU frame time, GPU frame time, and presentation/frame pacing separately.
- Record p50/p95/p99, resolution, render scale, sample count, scene geometry, shader variants, GPU/driver, and power state.
- Warm pipelines and assets before steady-state measurement; measure startup separately if relevant.
- Identify expensive passes using GPU timestamps or suitable platform profilers, accounting for instrumentation overhead.

## Hypothesis categories

- Fill rate / bandwidth: large render targets, overdraw, excessive intermediate textures.
- Compute: occupancy, register pressure, workgroup size, divergence, barriers, redundant memory traffic.
- Synchronization: CPU-GPU waits, map/readback, queue submission, pipeline creation, resource transitions.
- Shading: expensive texture sampling, dynamic loops, precision choices, redundant lighting work.
- Data transfer: frequent uploads, excessive buffer recreation, poorly batched draws/dispatches.

## Correctness and reporting

- Use identical camera, scene, lighting, and quality settings.
- Check visual differences and numeric tolerances after optimization.
- Report actual milliseconds saved and variability; do not convert a single noisy sample into a general speedup claim.
- Test on representative hardware; device-specific optimizations need fallbacks where portability matters.

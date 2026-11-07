---
name: webgpu-rendering
description: Design, implement, review, and debug Rust wgpu/Bevy renderers and WGSL shaders, including modular render graphs, materials, lighting, compute passes, and GPU resource lifecycles. Use for WebGPU rendering or compute correctness and architecture; invoke performance-engineering for measured optimization.
---
# WebGPU Rendering

Build the smallest correct observable GPU result first. Make contracts explicit before adding passes, resources, or abstraction layers. Target Rust `wgpu` and Bevy, checking installed versions rather than assuming API compatibility.

## Five contracts

1. **Capabilities:** adapter/device features, limits, formats, fallback behavior.
2. **Data:** WGSL host-shareable layouts, offsets, strides, padding, usage flags, bind-group visibility.
3. **Passes:** each pass's inputs, outputs, ordering, and authoritative resource ownership.
4. **Presentation:** render-target format, color space, depth, sample count, resizing, and output correctness.
5. **Lifecycle:** creation, caching, invalidation, device loss, teardown, and synchronization.

## Implementation protocol

- Inspect existing render graph, Bevy integration, shader conventions, and wgpu version before proposing changes.
- Describe new resources and pass dependencies in a small textual graph when nontrivial; identify read/write hazards and temporal history buffers.
- Specify shader bindings and host-side structures together. Verify alignment, address spaces, and uniform/storage layout requirements against the actual WGSL spec and API.
- Prefer stable resource allocations and cached pipelines; rebuild only when descriptors or dependencies change.
- Ensure over-dispatched compute invocations have bounds guards. Respect uniform-control-flow requirements for barriers.
- Distinguish synchronization/order guarantees from algorithmic race freedom. Never assume in-place cross-invocation updates are deterministic.
- Surface compilation and validation failures; do not bypass errors with unsafe casts or silently ignore them.
- Keep GPU readback out of frame-critical paths unless necessary and measured.
- Validate one minimal frame or numerical output before scaling up.

## Renderer-specific considerations

- **Bevy/wgpu:** distinguish main-world extraction, render-world preparation, queueing, graph execution, and resource ownership. Follow the installed Bevy API, not remembered examples.
- **OpenPBR:** preserve documented material semantics, parameter units, energy behavior, normal conventions, and color-space conversions. Validate under controlled lighting.
- **Radiance cascades / RCPG:** make cascade levels, coordinate transforms, radiance representation, sampling, temporal history, and compositing explicit. Validate edge cases and convergence separately from performance.
- **Modularity:** separate passes at genuine resource, scheduling, or ownership boundaries. Avoid one-use wrappers and speculative shader frameworks.
- **WGSL:** validate shader entry points, stage IO, binding compatibility, derivative restrictions, texture access, numerical assumptions, and feature requirements.

## Verification

Use compiler and shader validation, runtime assertions for internal invariants, minimal reproducible scenes, and controlled image comparisons. For visual changes, fix camera, geometry, materials, exposure, and light configuration before comparing. Inspect both GPU correctness and visual artifacts. Do not equate a compiling shader with a correct renderer.

## Reference loading

Read only the relevant reference:
- `references/wgsl-and-layouts.md` for WGSL, host layouts, and shader debugging.
- `references/render-graphs.md` for resource ownership, Bevy integration, temporal passes, and lighting.

For profiling and optimization, use `performance-engineering` rather than guessing at GPU bottlenecks.

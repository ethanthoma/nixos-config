# Render Graphs and Lighting

For each pass, record: purpose, dispatch/draw size, read resources, write resources, history dependencies, lifetime, and validation signal.

Example:

    geometry -> G-buffer/depth -> lighting -> postprocess -> present
                                  ^
                           cascade radiance

- Establish ownership of intermediate textures and buffers. Track resize invalidation and format changes.
- Distinguish transient resources from persistent history. Use ping-pong or separate buffers when a pass must read previous state while writing next state.
- Consider CPU extraction/prepare/queue phases separately from GPU graph execution in Bevy.
- For radiance cascades, specify coordinate frames, probe/grid resolution, cascade indexing, ray directions, compositing, and boundary handling. Check off-by-one, precision, and temporal stability.
- For physically based materials, verify parameter conventions, light transport approximations, exposure, tone mapping, and conservation expectations with reference scenes.
- Compare screenshots under fixed scene conditions; also validate numerical intermediates where possible.
- Profile after correctness, using GPU timestamps when supported and equivalent scene workloads.

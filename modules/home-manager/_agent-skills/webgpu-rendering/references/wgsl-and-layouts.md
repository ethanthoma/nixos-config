# WGSL and Host Layout Checklist

- Confirm exact `wgpu` and WGSL versions, enabled features, and shader compilation errors.
- Calculate `AlignOf`, `SizeOf`, member offsets, array strides, and uniform-specific constraints; do not assume every struct is simply 16-byte aligned.
- Check Rust host structs for explicit padding and bytemuck/Pod soundness where used.
- Verify binding group/index, resource type, shader-stage visibility, access mode, min binding size, and dynamic-offset alignment.
- Check texture format, filterability, sample type, storage access, and multisampling compatibility.
- Guard compute dispatch tail lanes and keep workgroup barriers in valid uniform control flow.
- Review floating-point stability: normalization of near-zero vectors, divisions, NaNs, precision, and overflow.
- Validate coordinate spaces (world/view/clip/tangent), handedness, depth convention, and linear versus encoded color.
- For debugging, reduce to a known output, isolate passes, label resources, and inspect shader diagnostics before optimizing.

Primary references: https://www.w3.org/TR/WGSL/ and https://docs.rs/wgpu/latest/wgpu/ . Use the version matching the repository when possible.

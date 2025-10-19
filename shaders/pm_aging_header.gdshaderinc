/*
* Header for the painted-metal aging shader.
* The header has been separated so that debugging shaders that render components
* like a canvas shader for displaying masks on their own can simply include this file.
*/

/// Parameters relating to mask scaling, time and rng
group_uniforms general_parameters;
uniform uint seed = 0; // Seed used by all pseudo-rng functions
uniform float uv_scale = 1.0; // Scale of the UV(W) coordinates used to sample procedural (3D) textures
uniform float patch_scale = 2.0; // Scaling of the paint wear and rust patches
uniform float wear_scale = 2.0; // Scaling of the wear masks that affects the strength of the other masks
uniform float pit_scale = 8.0; // Scaling of the pit mask that is used for pitting corrosion and paint wear.
uniform float detail_scale = 100.0; // Scaling of the mask that adds detail to the other masks
uniform float time_scale = 0.01; // Scales the affect of the age uniform
uniform float uniform_corrosion_speed = 0.005; // Speed of uniform corrosion vs local corrosion

/// Parameters relating to albedo rendering differences between godot render modes
group_uniforms albedo_mode;
uniform float forward_saturate = 1.0;
uniform float forward_darken = 0.3;
uniform float forward_contrast = 1.25;
uniform float forward_rust_saturate = 0.75;
uniform bool compat_mode = false; // Whether the shader should adjust to compatibility rendering
uniform float compat_saturate = 0.8;
uniform float compat_darken = 0.75;
uniform float compat_contrast = 1.2;
uniform float compat_grime_intensity = 0.5;
uniform float compat_rust_darken = 0.65;

/// Parameters related to performance adjustments
group_uniforms performance;
uniform int voronoi_fbm_iterations = 5;
uniform int snoise_fbm_iterations = 4;

/// Configuration parameters for the use of vertex colors as wear weights
group_uniforms vertex_colors;
uniform bool use_vertex_weight = false; // Higher vertex color values make their surroundings age faster
uniform float vertex_weight_scale = 1.0; // How strongly the surrounding area is affected by the vertex weight
uniform uint vertex_weight_channel = 0; // Color channel used as the weight factor

/// Wear scaling parameters that are local to the object (details on the effects are in the docs)
group_uniforms object_parameters;
uniform float age = 0.0;
uniform float paint_stability: hint_range(0.0, 1.0) = 0.5; // Affects residue, grime, roughness and yellowing

/// Wear scaling parameters of the environment context (details on the effects are in the docs)
group_uniforms context_parameters;
uniform float uv_and_heat: hint_range(0.0, 1.0) = 0.5; // UV and temperature intensity
uniform float pollution: hint_range(0.0, 1.0) = 0.5; // Acidity, toxicity, salinity, etc.
uniform float moisture: hint_range(0.0, 1.0) = 0.5; // Moisture, precipitation

/// The metallic base layer below the paint coating.
group_uniforms base_layer;
uniform float base_metallic = 0.6;
uniform sampler2D albedo_base;
uniform sampler2D normal_base : hint_normal;
uniform sampler2D roughness_base;

/// The paint coating above the base metallic layer.
group_uniforms paint_layer;
uniform bool use_paint_layer = true;
uniform float paint_metallic = 0.4;
uniform float paint_edge_sharpness: hint_range(0.0, 1.0) = 0.98;
uniform vec3 paint_yellowing: source_color = vec3(0.85, 0.85, 0.5); // Yellowing added during aging
uniform float paint_yellowing_intensity = 3.0; // Intensity by which obj/env factors should affect paint yellowing
uniform sampler2D albedo_paint;
uniform sampler2D normal_paint : hint_normal;
uniform sampler2D roughness_paint;

/// The grime accumulating at the edges of worn paint
group_uniforms grime;
uniform float grime_intensity = 4.0;
uniform float grime_falloff: hint_range(0.0, 1.0) = 0.9;
uniform vec3 grime_color : source_color = vec3(0.75, 0.45, 0.2);

/// The rust that is growing on the metallic base layer
group_uniforms rust;
uniform float rust_growth_factor = 200.0; // The factor with which rust grows in relation to other effects
uniform vec3 rust_color_1: source_color = vec3(0.65, 0.5, 0.1);
uniform vec3 rust_color_2: source_color = vec3(0.63, 0.38, 0.2);
uniform vec3 rust_color_3: source_color = vec3(0.55, 0.33, 0.2);
uniform vec3 rust_color_4: source_color = vec3(0.41, 0.3, 0.28);
uniform float rust_red_shift = 0.5; // Scales the mask texture based shift of the rust's red channel
uniform float rust_green_shift = 0.1; // Scales the mask texture based shift of the rust's green channel

#define INCLUDE_PARAMS_DEFINED
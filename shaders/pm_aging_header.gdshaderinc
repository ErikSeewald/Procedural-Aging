/*
* Header for the painted-metal aging shader.
* Contains uniforms and variables.
* The header has been separated so that debugging shaders that render components
* (like a canvas shader for displaying masks on their own) can simply include this file.
*/

group_uniforms render_parameters;
uniform bool compat_mode = false; // Whether the shader should adjust to compatibility rendering
uniform uint seed = 0; // Seed used by all pseudo-rng functions
uniform float uv_scale = 1.0; // Scale of the UV(W) coordinates used to sample procedural (3D) textures
uniform float patch_scale = 2.0; // Scaling of the larger paint wear patches
uniform float detail_scale = 1.0; // Scaling of the small paint wear patches that add detail
uniform float time_scale = 0.01; // Scaling of the time it takes to age

group_uniforms vertex_colors;
uniform bool use_vertex_weight = false; // If enabled, higher vertex color values make their surroundings age faster.
uniform float vertex_weight_scale = 1.0; // Scale of how strongly the surrounding area is affected by the vertex weight.
uniform uint vertex_weight_channel = 0; // Color channel to be used as the weight factor.

group_uniforms object_parameters;
uniform float age = 0.0;
uniform float paint_stability: hint_range(0.0, 1.0) = 0.5; // Affects residue, grime, roughness wear and yellowing
uniform float mechanical_load: hint_range(0.0, 1.0)= 0.5; // Intensity of mechanical wear the object is subject to

group_uniforms context_parameters;
uniform float uv_and_heat: hint_range(0.0, 1.0) = 0.5; // UV intensity, temperature intensity and variety
uniform float pollution: hint_range(0.0, 1.0) = 0.5; // Acidity, toxicity, salinity, etc.
uniform float moisture: hint_range(0.0, 1.0) = 0.5; // Average moisture, precipitation

group_uniforms base_layer;
uniform float base_metallic = 0.6;
uniform sampler2D albedo_base;
uniform sampler2D normal_base : hint_normal;
uniform sampler2D roughness_base;

group_uniforms paint_layer;
uniform float paint_metallic = 0.4;

// The residue left behind by worn away paint
const float residue_edge = 0.4;
uniform float residue_intensity = 3.0;
uniform float residue_falloff = 0.6;
uniform vec3 residue_color : source_color = vec3(0.7, 0.75, 0.7);

// The grime accumulating at the wear edges of paint
const float grime_edge = 0.35;
uniform float grime_intensity = 0.1;
uniform float grime_falloff = 1.0;
uniform vec3 grime_color : source_color = vec3(0.6, 0.3, 0.0);

uniform sampler2D albedo_paint;
uniform sampler2D normal_paint : hint_normal;
uniform sampler2D roughness_paint;

group_uniforms rust;
uniform float pitting_factor = 2.0;
uniform float pit_scale = 6.0;
uniform float rust_detail_scale = 100.0;
uniform float uniform_corrosion_speed = 0.001;

#define INCLUDE_PARAMS_DEFINED
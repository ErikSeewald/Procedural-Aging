/*
* Header for the painted-metal aging shader.
* The header has been separated so that debugging shaders that render components
* like a canvas shader for displaying masks on their own can simply include this file.
*/

// If this is uncommented, object and environment parameters (and seed) will be instance uniforms
// That means they will not be easily editable from the godot editor for quick visualization
// but in return objects can reuse the same material and only modify these uniform parameters.
//#define INSTANCE_UNIFORMS

/// Parameters relating to mask scaling, time and rng
group_uniforms general_parameters;
#ifdef INSTANCE_UNIFORMS
	instance 
#endif 
uniform uint seed = 0; // Seed used by all pseudo-rng functions

uniform float uv_scale = 1.0; // Scale of the UV(W) coordinates used to sample procedural (3D) textures
uniform float patch_scale = 2.0; // Scaling of the paint wear and rust patches
uniform float wear_scale = 2.0; // Scaling of the wear masks that affects the strength of the other masks
uniform float pit_scale = 8.0; // Scaling of the pit mask that is used for pitting corrosion and paint wear.
uniform float detail_scale = 100.0; // Scaling of the mask that adds detail to the other masks
uniform float time_scale = 0.01; // Scales the affect of the age uniform
uniform float uniform_corrosion_speed = 0.005; // Speed of uniform corrosion vs local corrosion
uniform float exposure = 1.0; // Linearly scales the final albedo

/// Parameters related to performance adjustments
group_uniforms performance;
uniform uint voronoi_fbm_iterations = 5;
uniform uint snoise_fbm_iterations = 4;

#ifdef BAKE_MODE
instance uniform int bake_target = 0;
#endif

/// Configuration parameters for the use of vertex colors as wear weights
group_uniforms vertex_colors;
uniform bool use_vertex_weight = false; // Higher vertex color values make their surroundings age faster
uniform float vertex_weight_scale = 1.0; // How strongly the surrounding area is affected by the vertex weight
uniform uint vertex_weight_channel = 0; // Color channel used as the weight factor

/// Wear scaling parameters that are local to the object (details on the effects are in the docs)
group_uniforms object_parameters;
#ifdef INSTANCE_UNIFORMS
	instance 
#endif 
uniform float age = 0.0;

#ifdef INSTANCE_UNIFORMS
	instance 
#endif 
uniform float paint_stability: hint_range(0.0, 1.0) = 0.5; // Affects residue, grime, roughness and yellowing

/// Wear scaling parameters of the environment context (details on the effects are in the docs)
group_uniforms context_parameters;
#ifdef INSTANCE_UNIFORMS
	instance 
#endif 
uniform float uv_and_heat: hint_range(0.0, 1.0) = 0.5; // UV and temperature intensity

#ifdef INSTANCE_UNIFORMS
	instance 
#endif 
uniform float pollution: hint_range(0.0, 1.0) = 0.5; // Acidity, toxicity, salinity, etc.

#ifdef INSTANCE_UNIFORMS
	instance 
#endif 
uniform float moisture: hint_range(0.0, 1.0) = 0.5; // Moisture, precipitation

/// The metallic base layer below the paint coating.
group_uniforms base_layer;
uniform sampler2D albedo_base : source_color; // Source color converts from srgb to linear
uniform sampler2D metallic_base;
uniform sampler2D roughness_base : hint_roughness_r;
uniform sampler2D normal_base : hint_normal;

/// The paint coating above the base metallic layer.
group_uniforms paint_layer;
uniform bool use_paint_layer = true;
uniform float paint_edge_sharpness: hint_range(0.0, 1.0) = 0.98;
uniform vec3 paint_yellowing: source_color = vec3(0.85, 0.85, 0.5); // Yellowing added during aging
uniform float paint_yellowing_intensity = 2.5; // Intensity by which obj/env factors should affect paint yellowing
uniform sampler2D albedo_paint : source_color; // Source color converts from srgb to linear
uniform sampler2D metallic_paint;
uniform sampler2D roughness_paint : hint_roughness_r;
uniform sampler2D normal_paint : hint_normal;

/// The grime accumulating at the edges of worn paint
group_uniforms grime;
uniform float grime_intensity = 4.0;
uniform float grime_falloff: hint_range(0.0, 1.0) = 0.9;
uniform vec3 grime_color : source_color = vec3(0.5, 0.25, 0.0);

/// The rust that is growing on the metallic base layer
group_uniforms rust;
uniform float rust_growth_factor = 200.0; // The factor with which rust grows in relation to other effects
uniform vec3 rust_color_1: source_color = vec3(0.5, 0.35, 0.0);
uniform vec3 rust_color_2: source_color = vec3(0.33, 0.22, 0.0);
uniform vec3 rust_color_3: source_color = vec3(0.2, 0.01, 0.02);
uniform vec3 rust_color_4: source_color = vec3(0.125, 0.035, 0.075);
uniform float rust_red_shift = 0.25; // Scales the mask texture based shift of the rust's red channel
uniform float rust_green_shift = 0.06; // Scales the mask texture based shift of the rust's green channel

#define INCLUDE_PARAMS_DEFINED
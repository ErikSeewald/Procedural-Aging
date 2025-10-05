/*
* Header for the painted-metal aging shader.
* Contains uniforms and variables.
* The header has been separated so that debugging shaders that render components
* (like a canvas shader for displaying masks on their own) can simply include this file.
*/

group_uniforms render_params;
uniform bool compat_mode = false;
uniform uint seed = 0;
uniform float uv_scale = 1.0;
uniform uint patch_size = 2;
uniform uint detail_size = 1;
uniform float time_scale = 0.05;

group_uniforms object_params;
uniform float age = 0.0;
uniform float paint_stability = 0.6; // 0.0 - 1.0
uniform float coat_thickness = 100.0; // micro meters
uniform float mechanical_load = 0.6; // 0.0 - 1.0

group_uniforms context_params;
uniform float uv_and_heat: hint_range(0.0, 1.0) = 0.5;
uniform float pollution: hint_range(0.0, 1.0) = 0.5;
uniform float moisture: hint_range(0.0, 1.0) = 0.5;

group_uniforms base_layer;
uniform float base_metallic = 0.6;
uniform sampler2D albedo_base;
uniform sampler2D normal_base : hint_normal;
uniform sampler2D roughness_base;

group_uniforms paint_layer;
uniform float paint_metallic = 0.4;

const float residue_edge = 0.4;
uniform float residue_intensity = 3.0;
uniform float residue_falloff = 0.6;
uniform vec3 residue_color : source_color = vec3(0.7, 0.75, 0.7);

const float grime_edge = 0.35;
uniform float grime_intensity = 0.1;
uniform float grime_falloff = 1.0;
uniform vec3 grime_color : source_color = vec3(0.6, 0.3, 0.0);

uniform sampler2D albedo_paint;
uniform sampler2D normal_paint : hint_normal;
uniform sampler2D roughness_paint;

#define INCLUDE_PARAMS_DEFINED
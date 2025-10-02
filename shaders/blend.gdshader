shader_type spatial;
render_mode specular_schlick_ggx;

uniform bool compat_mode = false;

uniform float age = 0.0; // UNUSED FOR NOW
uniform float temperature = 0.0;
uniform float instance_id = 0.0;

group_uniforms compute_params; // Queried by the compute shader. Not used here.
uniform uint patch_size = 1;
uniform uint detail_size = 1;
uniform float time_scale = 0.05;

group_uniforms compute_masks;
uniform sampler2D masks; // Divided into color channels
uniform float weights[1];

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

const float grime_edge = 0.3;
uniform float grime_intensity = 0.25;
uniform float grime_falloff = 1.0;
uniform vec3 grime_color : source_color = vec3(0.6, 0.3, 0.0);

uniform sampler2D albedo_paint;
uniform sampler2D normal_paint : hint_normal;
uniform sampler2D roughness_paint;

varying uint lod;
varying float seed;

#define INCLUDE_PARAMS_DEFINED
#include "paint_mask.gdshaderinc"

vec3 adjust_contrast(vec3 color, float factor)
{
	return (color - 0.5) * factor + 0.5;
}

vec3 desaturate(vec3 color, float factor)
{
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), color, factor);
}

void fragment()
{
	int mask_count = 1;

	vec3 base_col = texture(albedo_base, UV).rgb;
	float base_roughness = texture(roughness_base, UV).r;
	vec3 base_normal = texture(normal_base, UV).rgb;

	vec3 paint_col = texture(albedo_paint, UV).rgb;
	float paint_roughness = texture(roughness_paint, UV).r;
	vec3 paint_normal = texture(normal_paint, UV).rgb;

	vec3 albedo = paint_col;
	float metallic = paint_metallic;
	float roughness = paint_roughness;
	vec3 normal = paint_normal;

	vec2 du = dFdx(UV);
	vec2 dv = dFdy(UV);
	float pixel_size = length(du) + length(dv);
	lod = 16384u;
	vec2 snapped_uv = UV;
	if (pixel_size > 0.0008) 
	{
		const int N = 11;
		const float thresholds[N] = float[N](
			0.02, 0.016, 0.012, 0.01, 0.008, 0.006, 0.004, 0.003, 0.002, 0.0015, 0.0012
		);
		const uint lods[N] = uint[N](64u, 96u, 128u, 144u, 192u, 256u, 384u, 512u, 768u, 1024u, 1536u);

		for (int i = 0; i < N; ++i) 
		{
	    	if (pixel_size > thresholds[i])
			{
				lod = lods[i];
				break;
			}
		}

		snapped_uv = floor(UV * float(lod)) / float(lod);
	}


	seed = temperature + instance_id*0.0001;

	for (int i = 0; i < mask_count; i++)
	{
		if (i > 0) {break;} // Just layer one for debugging
		
		float w = paint_mask(snapped_uv) * weights[i];

		albedo = mix(albedo, base_col, w);
		roughness = mix(roughness, base_roughness, w);
		metallic = mix(metallic, base_metallic, w);
		normal = mix(normal, base_normal, w);

		if (w > residue_edge)
		{
			float factor = residue_intensity * clamp((residue_falloff - w), 0.0, 1.0);
			if (compat_mode) {factor *= 0.25;}
			albedo = mix(albedo, residue_color, factor);
		}
		else if (w > grime_edge)
		{
			float factor = grime_intensity * clamp((grime_falloff - w), 0.0, 1.0);
			if (compat_mode) {factor *= 0.5;}
			albedo = mix(albedo, grime_color, factor);
		}
	}

 	// Adjust contrast and reduce brightness because the defaults look awful
	if (!compat_mode) { albedo = adjust_contrast(albedo, 1.25) * 0.3; }
	else { albedo = desaturate(albedo, 0.8) * 0.75;}

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal;
}
shader_type spatial;
render_mode specular_schlick_ggx;
#include "pm_aging_header.gdshaderinc" // Uniforms, parameters and helper functions

void blend_paint_mask(inout vec3 albedo, inout float metallic, 
	inout float roughness, inout vec3 normal, vec2 uv, vec2 lod_uv)
{
	vec3 base_col = texture(albedo_base, uv).rgb;
	float base_roughness = texture(roughness_base, uv).r;
	vec3 base_normal = texture(normal_base, uv).rgb;

	vec3 paint_col = texture(albedo_paint, uv).rgb;
	float paint_roughness = texture(roughness_paint, uv).r;
	vec3 paint_normal = texture(normal_paint, uv).rgb;

	albedo = paint_col;
	metallic = paint_metallic;
	roughness = paint_roughness;
	normal = paint_normal;

	float w = paint_mask(lod_uv);

	float aw = w;
	float ht = moisture+uv_and_heat;
	if (w < residue_edge)
	 { 
		aw *= 0.75;
		
		albedo = mix(albedo, vec3(0.95, 0.95, 0.5), ht*0.25*w);
		roughness = mix(roughness, 1.0, ht*0.25*w);
		normal = mix(normal, base_normal, ht*0.5*w);
	}
	albedo = mix(mix(albedo, grime_color, pollution*0.25), base_col, aw);
	
	roughness = mix(roughness, base_roughness, w);
	metallic = mix(metallic, base_metallic, w);
	normal = mix(normal, base_normal, w);

	if (w > residue_edge - pollution*0.05 - ht*0.02)
	{
		float factor = residue_intensity * clamp((residue_falloff - w), 0.0, 1.0);
		if (compat_mode) {factor *= 0.35;}
		albedo = mix(albedo, residue_color, factor);
	}
	else if (w > grime_edge - pollution*0.1)
	{
		float factor = grime_intensity * clamp((grime_falloff - w), 0.0, 1.0);
		factor += pollution*0.2;
		albedo = mix(albedo, grime_color, factor);
	}
}

void fragment()
{
	float pixel_size = length(dFdx(UV)) + length(dFdy(UV));
	vec2 lod_uv = get_lod_uv(UV, pixel_size);
	
	vec3 albedo;
	float metallic;
	float roughness;
	vec3 normal;
	
	blend_paint_mask(albedo, metallic, roughness, normal, UV, lod_uv);
	mode_albedo_adjustment(albedo, compat_mode);

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal;
}
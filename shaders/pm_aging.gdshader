shader_type spatial;
render_mode specular_schlick_ggx;
#include "pm_aging_header.gdshaderinc"
#include "paint_mask.gdshaderinc"
#include "color_util.gdshaderinc"
#include "lod.gdshaderinc"

varying vec3 v_obj_pos;
varying vec3 v_obj_nrm;

void vertex()
{
	v_obj_pos = VERTEX;
	v_obj_nrm = NORMAL;
}

void blend_paint_mask(inout vec3 albedo, inout float metallic, 
	inout float roughness, inout vec3 normal, vec2 uv, vec3 mask_pos)
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

	float w = paint_mask(mask_pos);

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
	vec3 dx = dFdx(v_obj_pos);
	vec3 dy = dFdy(v_obj_pos);
	float pixel_size = max(length(dx), length(dy));
	
	vec3 mask_pos = v_obj_pos;
	vec3 lod_mask_pos = get_lod_mask_pos(mask_pos, pixel_size);
	lod_mask_pos *=  uv_scale;
	
	vec3 albedo;
	float metallic;
	float roughness;
	vec3 normal;
	
	blend_paint_mask(albedo, metallic, roughness, normal, UV, lod_mask_pos);
	mode_albedo_adjustment(albedo, compat_mode);

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal;
}
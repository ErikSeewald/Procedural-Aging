shader_type spatial;
#include "pm_aging_header.gdshaderinc"
#include "paint_mask.gdshaderinc"
#include "color_util.gdshaderinc"

varying vec3 obj_pos;
void vertex() { obj_pos = VERTEX; }

// Returns a level of detail factor based on pixel_size relative to
// object position. The factor is in the range of (0.0, 1.0).
float get_lod()
{
	vec3 dx = dFdx(obj_pos);
	vec3 dy = dFdy(obj_pos);
	float pixel_size = max(length(dx), length(dy));
	return clamp(pow(pixel_size * 650.0 + 0.75, -2), 0.0, 1.0);
}

// Using distinct cutoff edges for paint residue and accumulated grime,
// which are both achieved using blending, the smooth edges of the mask
// can be sharpened and intensified. The blend looks pretty flat without this.
void blend_grime_and_residue(inout vec3 albedo, float w)
{
	// Offset the edges by the corresponding context parameters
	float paint_stability_offset = (paint_stability - 0.5) * 0.05;
	float residue_edge_offset = pollution*0.05 + (moisture+uv_and_heat)*0.02 - paint_stability_offset;
	float grime_edge_offset = pollution*0.1 - paint_stability_offset;
	
	if (w > residue_edge - residue_edge_offset)
	{
		float factor = residue_intensity * clamp((residue_falloff - w), 0.0, 1.0);
		if (compat_mode) {factor *= 0.35;} // Compat rendering has much more intensity by default
		albedo = mix(albedo, residue_color, factor);
	}
	else if (w > grime_edge - grime_edge_offset)
	{
		float factor = grime_intensity * clamp((grime_falloff - w), 0.0, 1.0);
		factor += pollution*0.2; // Pollution should make more grime appear
		albedo = mix(albedo, grime_color, factor);
	}
}

void blend_paint_mask(inout vec3 albedo, inout float metallic, 
	inout float roughness, inout vec3 normal, vec2 uv)
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

	float w = paint_mask(obj_pos * uv_scale, get_lod());

 	// Intensify difference between inside and outside of the paint edges
	float adjusted_w = clamp(w + w - residue_edge, 0.0, 1.0);
	if (w < residue_edge)
	 { 
		// Reduce the wear/blend on the inside of the residue edge
		// for a stronger edge wear look.
		float stability_divsor = clamp(paint_stability, 0.35, 1.0);
		adjusted_w = w * 0.25 / stability_divsor;
		
		// Moisture and uv/heat should reduce gloss, surface roughness
		// and add yellowing to the paint surface.
		float mus = (moisture+uv_and_heat) * 0.25 / stability_divsor;
		const vec3 yellowing = vec3(0.95, 0.95, 0.5);
		albedo = mix(albedo, yellowing, mus*w);
		roughness = mix(roughness, 1.0, mus*w);
		normal = mix(normal, base_normal, mus*5.0*w); // Stronger reduction factor needed here
	}
	
	vec3 extra_grime = mix(albedo, grime_color, pollution*0.25);
	albedo = mix(extra_grime, base_col, adjusted_w);
	
	roughness = mix(roughness, base_roughness, adjusted_w);
	metallic = mix(metallic, base_metallic, adjusted_w);
	normal = mix(normal, base_normal, adjusted_w);

	// Order is important here. This step needs to happen after the others uniform
	// the parameters no longer make sense. Use the non adjusted weight here.
	blend_grime_and_residue(albedo, w);
}

void fragment()
{
	vec3 albedo;
	float metallic;
	float roughness;
	vec3 normal;
	
	blend_paint_mask(albedo, metallic, roughness, normal, UV);
	mode_albedo_adjustment(albedo, compat_mode);

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal;
}
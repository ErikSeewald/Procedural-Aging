shader_type spatial;
#include "pm_aging_header.gdshaderinc"
#include "masks.gdshaderinc"
#include "color_util.gdshaderinc"

varying vec3 obj_pos;
varying float vertex_weight;
void vertex()
{
	obj_pos = VERTEX;

	vertex_weight = 0.0;
	if (use_vertex_weight)
	{
		switch (vertex_weight_channel)
		{
			case 0u: vertex_weight = COLOR.r; break;
			case 1u: vertex_weight = COLOR.g; break;
			case 2u: vertex_weight = COLOR.b; break;
			case 3u: vertex_weight = COLOR.a; break;
		}
		vertex_weight *= vertex_weight_scale;
	}
}

// Returns a level of detail factor based on pixel_size relative to
// object position. The factor is in the range of (0.0, 1.0).
float get_lod()
{
	vec3 dx = dFdx(obj_pos * uv_scale);
	vec3 dy = dFdy(obj_pos * uv_scale);
	float pixel_size = max(length(dx), length(dy));
	return clamp(pow(pixel_size * 500.0, -0.5), 0.0, 1.0);
}

uniform float sharpness = 0.001;

// Using distinct cutoff edges for paint residue and accumulated grime,
// which are both achieved using blending, the smooth edges of the mask
// can be sharpened and intensified. The blend looks pretty flat without this.
void blend_grime_and_residue(inout vec3 albedo, float w, 
	float residue_edge, float grime_edge)
{
	float residue_mask = smoothstep(residue_edge, residue_edge + sharpness, w); 
	float residue_fade = clamp((residue_falloff - w), 0.0, 1.0);
	float residue_factor = residue_mask * residue_intensity * residue_fade;

	float compat_scale = mix(1.0, 0.35, float(compat_mode));
	residue_factor *= compat_scale;

	float grime_mask = smoothstep(grime_edge, grime_edge + sharpness, w);
	float grime_fade = clamp((grime_falloff - w), 0.0, 1.0);
	float grime_factor = grime_mask * grime_intensity * grime_fade;
	grime_factor += pollution * 0.2;

	float total_factor = max(residue_factor, grime_factor);
	vec3 target_color = mix(grime_color, residue_color, step(residue_edge, w));
	albedo = mix(albedo, target_color, total_factor);
}

void blend_paint_mask(inout vec3 albedo, inout float metallic,
	inout float roughness, inout vec3 normal, vec2 uv, float w,
	float residue_edge, float grime_edge)
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

 	// Intensify difference between inside and outside of the paint edges
	float adjusted_w = clamp(w + w - residue_edge, 0.0, 1.0);
	float normal_factor = 1.0; // Outside of residue it should be 100% base normal
	if (w < residue_edge)
	 {
		// Reduce the wear/blend on the inside of the residue edge
		// for a stronger edge wear look.
		float stability_divsor = clamp(paint_stability, 0.35, 1.0);
		adjusted_w = w * 0.25 / stability_divsor;
		normal_factor = adjusted_w;

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
	normal = mix(normal, base_normal, normal_factor);

	// Order is important here. This step needs to happen after the others uniform
	// the parameters no longer make sense. Use the non adjusted weight here.
	blend_grime_and_residue(albedo, w, residue_edge, grime_edge);
}

void blend_rust_mask(inout vec3 albedo, inout float metallic,
	inout float roughness, inout vec3 normal, float pm_weight, float w, float grime_edge)
{
	w *= 100.0 * (pm_weight - grime_edge);
	albedo = mix(albedo, mix(vec3(0.55, 0.4, 0.2), vec3(0.45, 0.30, 0.2), smoothstep(0.2, 1.0, w)), clamp(w, 0.0, 1.0));
	albedo = mix(albedo, vec3(0.35, 0.1, 0.0), smoothstep(1.0, 3.0, w )*0.3);
	roughness = mix(roughness, clamp(roughness + 0.3, 0.0, 1.0), clamp(w, 0.0, 1.0));
	
	normal = normalize(normal + w * 0.15 * (normal - obj_pos));
}

void fragment()
{
	vec3 albedo;
	float metallic;
	float roughness;
	vec3 normal;
	
	// Offset the edges by the corresponding context parameters
	float paint_stability_offset = (paint_stability - 0.5) * 0.05;
	float residue_edge = residue_edge_default - (pollution*0.05 + (moisture+uv_and_heat)*0.02 - paint_stability_offset);
	float grime_edge = grime_edge_default - (pollution*0.1 - paint_stability_offset);
	
	float detail_mask = get_detail_mask(obj_pos * uv_scale, vertex_weight);
	float pm_weight = paint_mask(obj_pos * uv_scale, vertex_weight, detail_mask);
	
	blend_paint_mask(albedo, metallic, roughness, normal, UV, pm_weight, residue_edge, grime_edge);
	
	if (pm_weight > grime_edge) 
	{
		float w = rust_mask(obj_pos * uv_scale, vertex_weight, pm_weight, detail_mask, get_lod());
		blend_rust_mask(albedo, metallic, roughness, normal, pm_weight, w, grime_edge);
	}
	
	mode_albedo_adjustment(albedo, compat_mode);

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal;
}
shader_type spatial;
#include "pm_aging_header.gdshaderinc"
#include "masks.gdshaderinc"
#include "color_util.gdshaderinc"

// Struct for compact inout passing of this shader's output values.
struct outputs
{
	vec3 albedo;
	float metallic;
	float roughness;
	vec3 normal;
	float specular;
};

const float grime_edge_default = 0.4; // The default edge (paint mask value) of grime deposition

varying vec3 obj_pos; // Interpolated fragment position in object space
varying float vertex_weight; // Interpolated vertex paint weight at the current fragment 

// The vertex shader only pepares the interpolated obj_pos vector
// and saves the vertex paint weight.
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
// object position.
// The value rises exponentially with larger pixel size.
float get_lod()
{
	vec3 dx = dFdx(obj_pos * uv_scale);
	vec3 dy = dFdy(obj_pos * uv_scale);
	float pixel_size = max(length(dx), length(dy));
	return clamp(exp(pixel_size*100.0) - 1.0, 0.0, 1.0);
}

// Adjusts contrast and reduces brightness based on the selected rendering mode.
vec3 mode_albedo_adjustment(vec3 albedo, bool is_compat_mode)
{
	if (is_compat_mode)
	{
		albedo = desaturate(albedo, compat_saturate);
		albedo = adjust_contrast(albedo, compat_contrast) * compat_darken;
	}

	else
	{
		albedo = desaturate(albedo, forward_saturate);
		albedo = adjust_contrast(albedo, forward_contrast)  * forward_darken;
	}
	
	return albedo;
}

// Returns a factor describing the desired strength of the aging effects
// based on the actual age and the uniforms that affect it.
float get_aged_strength()
{
 	// Moisture has the strongest effect on paint wear, uv/heat and pollution less so.
	// Note: Though the paint mask effects the rust growth, when the coating is gone or unused
	// it no longer fully makes sense to use this paint based weight distribution.
	// However, in favor of having a single fixed heuristic for both cases, no distinction is made.
	const float moisture_w = 1.0;
	const float uv_w = 0.85;
	const float pollution_w = 0.25;
	float env = moisture*moisture_w + uv_and_heat*uv_w + pollution*pollution_w;
	
	float weight = (1.0 + vertex_weight);
	return env * weight * age * time_scale;
}

// Returns the grime accumulation edge offset by the corresponding env/object parameters.
float offset_grime_edge()
{
	const float pollution_w = 0.05; // Pollution should have the strongest effect on grime
	float pollution_offset = pollution * pollution_w;
	
	const float moisture_uv_w = 0.02; // Moisture and uv/heat both have the same effect on the offset
	float moisture_uv_offset = (moisture+uv_and_heat) * moisture_uv_w;

	float edge_offset = pollution_offset + moisture_uv_offset;
	
	const float sability_w = 0.03; // Strong stability should reduce the grime edge offset
	float stability_offset = paint_stability * sability_w;
	return grime_edge_default - edge_offset + stability_offset;
}

// Blends grime into the edges of the paint mask to simulate grime accumulation.
// Modifies the given inout outpus based on the paint mask weight and the version
// of it that has been smoothed around the grime edge, defining grime accumulation spots.
void blend_grime(inout outputs outs, float pm_weight, float smooth_pm_weight)
{	
	// Kept constant instead of as uniforms because these values, 
	// unlike grime color, are not very dependant on the base and paint albedo.
	const float grime_roughness = 0.8;
	const float grime_specular = 0.1;
	
	// Fade out the grime intensity based on the selected falloff
	float fade_factor = (1.0 - grime_falloff) + grime_edge_default;
	float grime_fade = clamp((fade_factor - pm_weight), 0.0, 1.0);
	
	float grime_factor = smooth_pm_weight * grime_intensity * grime_fade;
	grime_factor *= mix(1.0, compat_grime_intensity, float(compat_mode));

	outs.albedo = mix(outs.albedo, grime_color, grime_factor);
	outs.roughness = mix(outs.roughness, grime_roughness, grime_factor);
	outs.specular = mix(outs.specular, grime_specular, grime_factor);
}

// Blends the paint layer on top of the base layer in the given inout outputs
// based on the given paint mask weight.
// Factors in the grime edge to apply certain effects only on either side of it.
void blend_paint_mask(inout outputs outs, vec2 uv, float pm_weight, float smooth_pm_weight)
{
	vec3 base_col = outs.albedo;
	float base_roughness = outs.roughness;
	float base_metallic_adj = outs.metallic;
	vec3 base_normal = outs.normal;

	// Replace base with paint layer and wear it away
	outs.albedo = texture(albedo_paint, uv).rgb;
	outs.metallic = paint_metallic;
	outs.roughness = texture(roughness_paint, uv).r;
	outs.normal = texture(normal_paint, uv).rgb;

 	// Intensify difference between inside and outside of the paint edges
	float adjusted_w = 1.0; // Force weight to 1.0 beyond grime edge
	
	// Limit stability factor to this range to avoid extreme results that
	// can cause aliasing or complete blur.
	const float min_stability = 0.25;
	const float max_stability = 0.75;
	float stability_factor = clamp(1.0 - paint_stability, min_stability, max_stability);
	adjusted_w = mix(pm_weight * stability_factor, 1.0, smooth_pm_weight);

	// Moisture and uv/heat should reduce gloss and add yellowing to the paint surface.
	const float m_stength = 1.25; // Intensify a bit to be noticable at all params
	float m = (moisture+uv_and_heat) * m_stength * stability_factor;
	
	vec3 yellowed_albedo = mix(outs.albedo, paint_yellowing, m*pm_weight);
	vec3 adjusted_normal = mix(outs.normal, base_normal, m*pm_weight);
	
	outs.albedo = mix(yellowed_albedo, outs.albedo, smooth_pm_weight);
	outs.normal = mix(adjusted_normal, outs.normal, smooth_pm_weight);
	

	vec3 extra_grime = mix(outs.albedo, grime_color, pollution * adjusted_w);
	outs.albedo = mix(extra_grime, base_col, smoothstep(0.0, 1.0, adjusted_w*adjusted_w*4.0));

	outs.roughness = mix(outs.roughness, base_roughness, adjusted_w);
	outs.metallic = mix(outs.metallic, base_metallic_adj, adjusted_w);
	outs.normal = mix(outs.normal, base_normal, adjusted_w);
}

void blend_rust_mask(inout outputs outs, float w, maskset mask_set)
{
	vec3 col = mix(outs.albedo, rust_color_1, smoothstep(0.0, 0.1, w));
	col = mix(col, rust_color_2, smoothstep(1.0, 2.0, w));
	col = mix(col, rust_color_3, smoothstep(2.0, 3.0, w));
	col = mix(col, rust_color_4, smoothstep(5.0, 10.0, w));

	col.r += mask_set.detail_mask * rust_red_shift;
	col.g += mask_set.detail_mask * rust_green_shift;

	float pollution_factor = (0.5+pollution);
	col = desaturate(col, clamp(1.0 - mask_set.pit_mask*mask_set.detail_mask* pollution_factor, 0.0, 1.0));
	if (!compat_mode) { col = desaturate(col, 0.75); }
	else { col *= compat_rust_darken; }

	w = smoothstep(0.0, 1.0, clamp(w, 0.0, 1.0));
	outs.albedo = mix(outs.albedo, col, w);

	float scaled_w = w * 0.15;
	outs.roughness = clamp(outs.roughness + scaled_w * pollution_factor, 0.0, 0.9);
	outs.metallic = clamp(outs.metallic - scaled_w, 0.2, 1.0);
	outs.specular = clamp(outs.specular - scaled_w * pollution_factor, 0.2, 1.0);
}

void fragment()
{
	// Default the outputs to the base layer, age it, and then 
	// put the paint layer on top based on the paint mask.
	outputs outs;
	outs.albedo = texture(albedo_base, UV).rgb;
	outs.metallic = base_metallic;
	outs.roughness = texture(roughness_base, UV).r;
	outs.normal = texture(normal_base, UV).rgb;
	outs.specular = SPECULAR;
	
	// The scaling for the seed was heuristically chosen to look good for both
	// very high and very low uint seeds. A low scaling means no big difference
	// between neighbor seeds while a high scaling can cause maxing out the float range
	// for large seeds.
	float seed_f = float(seed) / float(0xffffffffu) * 1.0e7;

	// The interpolated object space position scaled by uv_scale is used by all
	// procedural sampling functions.
	vec3 pos = obj_pos*uv_scale;

	float lod = get_lod();
	float strength = get_aged_strength();

	// Calculate these once and then compactly pass them around in the maskset struct.
	maskset mask_set;
	mask_set.detail_mask = get_detail_mask(pos, lod);
	mask_set.pit_mask = get_pit_mask(pos, seed_f);
	mask_set.wear_mask = get_wear_mask(pos, seed_f);

	float pm_weight = 1.0; // Weight of the paint mask where 1.0 means the paint is fully removed.
	if (use_paint_layer)
	{
		pm_weight = paint_mask(pos, strength, mask_set, seed_f);
	}
	
	// Use an offset based on the edge sharpness to smoothstep the weight around the edge
	float grime_edge = offset_grime_edge();
	float offset = (1.0 - paint_edge_sharpness);
	float smooth_pm_weight = smoothstep(grime_edge - offset, grime_edge + offset, pm_weight);
	
	if (pm_weight > grime_edge) // Rust only needs to be calculated where it can actually be visible
	{
		float rust_w = rust_mask(strength, mask_set);
		rust_w *= rust_growth_factor * (pm_weight - grime_edge); // Rust grows more strongly where paint has worn away
		blend_rust_mask(outs, rust_w, mask_set);
	}
	
	blend_paint_mask(outs, UV, pm_weight, smooth_pm_weight);
	blend_grime(outs, pm_weight, smooth_pm_weight);
	
	ALBEDO = mode_albedo_adjustment(outs.albedo, compat_mode);
	METALLIC = outs.metallic;
	ROUGHNESS = outs.roughness;
	NORMAL_MAP = outs.normal;
	SPECULAR = outs.specular;
}
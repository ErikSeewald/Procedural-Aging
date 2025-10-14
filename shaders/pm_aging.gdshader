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
};

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

// Using distinct cutoff edges for accumulated grime,
// the smooth edges of the mask can be sharpened and intensified.
// The blend looks pretty flat without this.
void blend_grime(inout outputs outs, float w,
	float grime_edge, float lod)
{
	float s = 0.02 / (lod*lod);

	float grime_mask = smoothstep(grime_edge, grime_edge + s, w);
	float grime_fade = clamp((grime_falloff - w), 0.0, 1.0);
	float grime_factor = grime_mask * grime_intensity * grime_fade;

	float compat_scale = mix(1.0, 0.35, float(compat_mode));
	grime_factor *= compat_scale;

	outs.albedo = mix(outs.albedo, grime_color, grime_factor);
	outs.roughness = mix(outs.roughness, clamp(outs.roughness + 0.3, 0.0, 1.0), grime_factor);
}

void blend_paint_mask(inout outputs outs, vec2 uv, float w,
	float grime_edge, float lod, float rust_w)
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
	float adjusted_w = clamp(w + w - grime_edge, 0.0, 1.0);
	float normal_factor = 1.0; // Outside of grime it should be 100% base normal
	if (w < grime_edge)
	 {
		// Reduce the wear/blend on the inside of the grime edge
		// for a stronger edge wear look.
		float stability_divsor = clamp(paint_stability, 0.35, 1.0);
		adjusted_w = w * 0.25 / stability_divsor;
		normal_factor = adjusted_w;

		// Moisture and uv/heat should reduce gloss, surface roughness
		// and add yellowing to the paint surface.
		float mus = (moisture+uv_and_heat) * 0.25 / stability_divsor;
		const vec3 yellowing = vec3(0.95, 0.95, 0.5);
		outs.albedo = mix(outs.albedo, yellowing, mus*w);
		outs.roughness = mix(outs.roughness, 1.0, mus*w);
		outs.normal = mix(outs.normal, base_normal, mus*w);
	}


	vec3 extra_grime = mix(outs.albedo, grime_color, pollution * adjusted_w);
	outs.albedo = mix(extra_grime, base_col, smoothstep(0.0, 1.0, adjusted_w*adjusted_w*4.0));

	outs.roughness = mix(outs.roughness, base_roughness, adjusted_w);
	outs.metallic = mix(outs.metallic, base_metallic_adj, adjusted_w);
	outs.normal = mix(outs.normal, base_normal, normal_factor);

	// Order is important here. This step needs to happen after the others uniform
	// the parameters no longer make sense. Use the non adjusted weight here.
	blend_grime(outs, w, grime_edge, lod);
}


void blend_rust_mask(inout outputs outs, float w, maskset mask_set)
{
	vec3 col = mix(outs.albedo, rust_color_1, smoothstep(0.0, 0.1, w));
	col = mix(col, rust_color_2, smoothstep(1.0, 2.0, w));
	col = mix(col, rust_color_3, smoothstep(2.0, 3.0, w));
	col = mix(col, rust_color_4, smoothstep(5.0, 10.0, w));

	col.r += mask_set.detail_mask * rust_red_shift;
	col.g += mask_set.detail_mask * rust_green_shift;

	col = desaturate(col, clamp(1.0 - mask_set.pit_mask*mask_set.detail_mask, 0.0, 1.0));
	col = desaturate(col, 0.75);

	outs.albedo = mix(outs.albedo, col, clamp(w, 0.0, 1.0));

	// TODO: This is a goop of meaninglessness
	for (int i = 0; i < 3; ++i)
	{
		outs.roughness = mix(outs.roughness, clamp(outs.roughness + 0.2, 0.0, 0.95), smoothstep(float(i), float(i*2) + 2.0, w ));
		outs.metallic = mix(outs.metallic, clamp(outs.metallic - 0.1, 0.2, 1.0), smoothstep(float(i), float(i*2) + 0.5, w ));
	}
}

void fragment()
{
	outputs outs;

	// Offset the edges by the corresponding context parameters
	float stability_offset = (paint_stability - 0.5) * 0.05;
	float grime_edge = grime_edge_default - (pollution*0.05 + (moisture+uv_and_heat)*0.02 - stability_offset);

	// Use maskset struct to compactly pass these around
	maskset mask_set;
	mask_set.detail_mask = get_detail_mask(obj_pos * uv_scale);
	mask_set.pit_mask = get_pit_mask(obj_pos * uv_scale);
	mask_set.wear_mask = get_wear_mask(obj_pos * uv_scale);

	float lod = get_lod();
	float pm_weight = 1.0;
	if (use_paint_layer)
	{
		pm_weight = paint_mask(obj_pos * uv_scale, vertex_weight, mask_set);
	}

	outs.albedo = texture(albedo_base, UV).rgb;
	outs.metallic = base_metallic;
	outs.roughness = texture(roughness_base, UV).r;
	outs.normal = texture(normal_base, UV).rgb;

	float rust_w = 0.0;
	if (!use_paint_layer || pm_weight > grime_edge)
	{
		rust_w = rust_mask(obj_pos * uv_scale, vertex_weight, mask_set, lod);
		rust_w *= 200.0 * (pm_weight - grime_edge);
		blend_rust_mask(outs, rust_w, mask_set);
	}
	blend_paint_mask(outs, UV, pm_weight, grime_edge, lod, rust_w);

	mode_albedo_adjustment(outs.albedo, compat_mode);


	ALBEDO = outs.albedo;
	METALLIC = outs.metallic;
	ROUGHNESS = outs.roughness;
	NORMAL_MAP = outs.normal;
}
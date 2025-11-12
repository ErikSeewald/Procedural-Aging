/*
* IMPORTANT:
* 1. This shader is built for forward+ and mobile rendering (Godot v4.5).
* 	Running it with the compatibility renderer causes color issues.
* 2. Any source shader than includes this file NEEDS to define "SHADER_TYPE_DEFINED"
*/

#include "pma_header.gdshaderinc"
#include "masks.gdshaderinc"

// If BAKE_MODE is defined, the shader will render it's output
// (based on bake_target uniform) to flat UV space so the texture can be saved.
#ifdef BAKE_MODE
render_mode unshaded, cull_disabled, depth_test_disabled;
#endif

// Struct for compact inout passing of this shader's output values.
struct outputs
{
	vec3 albedo;
	float metallic;
	float roughness;
	vec3 normal;
};

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

#ifdef BAKE_MODE
	// Project to render uv map. Since obj_pos is set prior, it will
	// correctly map the 3D noise matching object position to the flat UV.
	POSITION = vec4(UV*2.0 - 1.0, 0.0, 1.0);
#endif
}

// Returns a level of detail factor based on pixel_size relative to
// object position.
// The value rises exponentially with larger pixel size.
// The growth is tuned for the lod usage in the detail mask.
float get_lod()
{
#ifdef SHADER_TYPE_DEFINED
	vec3 dx = dFdx(obj_pos * uv_scale);
	vec3 dy = dFdy(obj_pos * uv_scale);
	float pixel_size = max(length(dx), length(dy));
	return exp(pixel_size*50.0) - 1.0;
#else
	return 0.0;
#endif
}

// Desaturates the given color based on the given factor using
// the luminance formula.
vec3 desaturate(vec3 color, float factor)
{
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), color, factor);
}

// Returns a factor describing the desired intensity of the aging effects
// based on the actual age and the uniforms that affect it.
float get_weathering_intensity()
{
 	// Moisture has the strongest effect on paint wear, uv/heat and pollution less so.
	// Note: Though the paint mask effects the rust growth, when the coating is gone or unused
	// it no longer fully makes sense to use this paint based weight distribution.
	// However, in favor of having a single fixed heuristic for both cases, no distinction is made.
	const float moisture_w = 1.0;
	const float uv_w = 0.85;
	const float pollution_w = 0.25;
	float env = moisture*moisture_w + uv_and_heat*uv_w + pollution*pollution_w;

	return time_scale * env * age * (1.0 + vertex_weight);
}

const float paint_edge_default = 0.4; // Edge in paint mask value

// Returns the edge of paint wear offset by the corresponding env/object parameters.
// This also directly affects grime deposition, which follows this edge.
float offset_paint_edge()
{
	const float pollution_w = 0.05; // Pollution should have the strongest effect on grime/paint edge
	float pollution_offset = pollution * pollution_w;

	const float moisture_uv_w = 0.02; // Moisture and uv/heat both have the same effect on the offset
	float moisture_uv_offset = (moisture+uv_and_heat) * moisture_uv_w;

	float edge_offset = pollution_offset + moisture_uv_offset;

	const float sability_w = 0.03; // Strong stability should reduce the  edge offset
	float stability_offset = paint_stability * sability_w;
	return paint_edge_default - edge_offset + stability_offset;
}

// Blends grime into the edges of the paint mask to simulate grime accumulation.
// Modifies the given inout outpus based on the paint mask weight and the version
// of it that has been smoothed around the grime edge, defining grime accumulation spots.
// Grime deposition would not be very visible along rust, which is why computation time is saved
// instead (and more importantly, less complexity is added) by not considering it.
void blend_grime(inout outputs outs, float paint_mask, float smooth_paint_mask)
{
	// Fade out the grime intensity based on the selected falloff.
	// Less falloff means a greater fade_edge and thereby grime_fade stays greater,
	// decreasing grime_weight less.
	// (Not using smooth_paint_mask here as the regions further beyond the edges
	// are also important for the distribution but are flattened in the smoothstep)
	float fade_edge = (1.0 - grime_falloff) + paint_edge_default;
	float grime_fade = clamp(fade_edge - paint_mask, 0.0, 1.0);
	float grime_weight = smooth_paint_mask * grime_intensity * grime_fade;
	
	// Kept constant instead of as uniforms because these values,
	// unlike grime color, are not very dependant on the base and paint albedo.
	const float grime_roughness = 1.0;
	outs.roughness = mix(outs.roughness, grime_roughness, grime_weight);

	outs.albedo = mix(outs.albedo, grime_color, grime_weight);
	
	// Stronger pollution should add some extra grime beyond just the edges
	const float extra_grime_factor = 0.25; // Enough to be visible but subtle
	outs.albedo = mix(outs.albedo, grime_color, pollution * extra_grime_factor);
}

// Blends the paint layer on top of the base layer in the given inout outputs
// based on the given paint mask weight and the version of it that has
// been smoothed around the grime edge.
void blend_paint_mask(inout outputs outs, vec2 uv, float paint_mask, float smooth_paint_mask)
{
	vec3 base_col = outs.albedo;
	float base_roughness = outs.roughness;
	float base_metallic = outs.metallic;
	vec3 base_normal = outs.normal;

	// Replace base with paint layer and wear it away
	outs.albedo = texture(albedo_paint, uv).rgb;
	outs.metallic = texture(metallic_paint, uv).r;
	outs.roughness = texture(roughness_paint, uv).r;
	outs.normal = texture(normal_paint, uv).rgb;

	// Limit stability factor to this range to avoid extreme results that
	// can cause aliasing or complete blur.
	const float min_stability = 0.25;
	const float max_stability = 0.75;
	float stability_factor = clamp(1.0 - paint_stability, min_stability, max_stability);

	// Moisture and uv/heat should further wear the normal and add yellowing to the paint surface.
	float m = (moisture+uv_and_heat) * stability_factor;

 	// paint_mask is squared in the factor for stronger edges
	float yellowing_factor = m * paint_mask * paint_mask * paint_yellowing_intensity;
	outs.albedo = mix(outs.albedo, paint_yellowing, yellowing_factor);

	outs.normal = mix(outs.normal, base_normal, m * paint_mask);

	// Now expose the base layer below the paint again.
 	// Intensify difference between inside and outside of the paint edges
	float adjusted_w = 1.0; // Force weight to 1.0 beyond grime edge
	adjusted_w = mix(paint_mask * stability_factor, adjusted_w, smooth_paint_mask);
	
	outs.albedo = mix(outs.albedo, base_col, adjusted_w);
	outs.roughness = mix(outs.roughness, base_roughness, adjusted_w);
	outs.metallic = mix(outs.metallic, base_metallic, adjusted_w);
	outs.normal = mix(outs.normal, base_normal, adjusted_w);
}

// Blends rust onto the base layer in the given inout outputs
// based on the given rust mask weight.
// Unlike the paint blending function, this blend also uses the maskset
// to add additional color detail to the rust mask.
void blend_rust_mask(inout outputs outs, float rust_mask, maskset mask_set)
{
	// These values were heuristically chosen to roughly match patterns in
	// rust images. They are kept constant to avoid too many parameters and
	// dependencies.
	const float ceil_1 = 0.5;
	const float ceil_2 = 2.0;
	const float ceil_3 = 2.5;
	const float ceil_4 = 10.0;

	// Initialize the rust color by smoothstepping the rust intensity colors based on weight
	vec3 rust_col = mix(outs.albedo, rust_color_1, smoothstep(0.0, ceil_1, rust_mask));
	rust_col = mix(rust_col, rust_color_2, smoothstep(0.0, ceil_2, rust_mask));
	rust_col = mix(rust_col, rust_color_3, smoothstep(0.0, ceil_3, rust_mask));
	rust_col = mix(rust_col, rust_color_4, smoothstep(0.0, ceil_4, rust_mask));

	// Using the detail mask to shift red and green adds color detail missing from the rust mask
	// and thereby a more nuanced "growth" look
	rust_col.r += mask_set.detail_mask * rust_red_shift;
	rust_col.g += mask_set.detail_mask * rust_green_shift;

	// Stronger rust intensity should desaturate more strongly.
	// The reason this is not simply done by desaturating the rust colors is to add
	// further detail to the saturation with the maskset and to scale it based on pollution.
	// The lack of clamping of the desaturation weight also allows for some spots to receive
	// extra saturation because of negative values in the pit mask. This adds further detail.
	float pollution_factor = (0.5 + pollution); // Anything lower than 0.5 looks too flat
	float desat_w = 1.0 - mask_set.pit_mask * mask_set.detail_mask * pollution_factor;
	rust_col = desaturate(rust_col, desat_w);

	// The intensities beyond the clamp range were only useful for adding detail to
	// the rust color but are not needed in blending.
	rust_mask = clamp(rust_mask, 0.0, 1.0);
	outs.albedo = mix(outs.albedo, rust_col, rust_mask);

	// To not deviate too drastically from the "physiochemical" look of the material,
	// the other outputs are blended with a much smaller weight.
	const float scale_factor = 0.5;
	float scaled_w = rust_mask * pollution_factor * scale_factor; 
	outs.roughness = mix(outs.roughness, 1.0, scaled_w);

	// While real rust would affect the metallic value, for the visual look it
	// is more appropriate to focus on roughness only, as decreasing metallic makes the
	// rust surface look out of place, especially with regard to lighting.
}

void fragment()
{
#ifndef SHADER_TYPE_DEFINED
	return; // Make it obvious when SHADER_TYPE_DEFINED is missing
#endif

	// Default the outputs to the base layer, age it, and then
	// put the paint layer on top based on the paint mask.
	outputs outs;
	outs.albedo = texture(albedo_base, UV).rgb;
	outs.metallic = texture(metallic_base, UV).r;
	outs.roughness = texture(roughness_base, UV).r;
	outs.normal = texture(normal_base, UV).rgb;

	// The uint seed needs to be wrapped in a lower range because high values eventually
	// mean floats cannot represent differences of 1 in the seed.
	// Even below the point where step sizes of 1 are no longer representable,
	// high seeds start to look strange so the cutoff is even lower.
	const uint wrap = 0x10000u;
	float seed_f = float(seed % wrap);

	// The interpolated object space position scaled by uv_scale is used by all
	// procedural sampling functions.
	vec3 pos = obj_pos*uv_scale;

	float lod = get_lod();
	float intensity = get_weathering_intensity();

	// Calculate these once and then compactly pass them around in the maskset struct.
	maskset mask_set;
	mask_set.detail_mask = get_detail_mask(pos, lod);
	mask_set.pit_mask = get_pit_mask(pos, seed_f);
	mask_set.wear_mask = get_wear_mask(pos, seed_f);

	float paint_mask = 1.0; // 1.0 means the paint is fully removed.
	if (use_paint_layer)
	{
		paint_mask = get_paint_mask(pos, intensity, mask_set, seed_f);
	}

	// Use an offset based on the edge sharpness to smoothstep the weight around the edge
	float paint_edge = offset_paint_edge();
	float offset = (1.0 - paint_edge_sharpness);
	float smooth_paint_mask = smoothstep(paint_edge - offset, paint_edge + offset, paint_mask);

	if (paint_mask > paint_edge) // Rust only needs to be calculated where it can actually be visible
	{
		float rust_mask = get_rust_mask(intensity, mask_set);
		
		// Rust grows more strongly where paint has worn away (use paint_mask instead of smoothed
		// mask here because rust_mask also encodes "how long" the surface has been exposed)
		rust_mask *= rust_growth_factor * (paint_mask - paint_edge);
		blend_rust_mask(outs, rust_mask, mask_set);
	}

	if (use_paint_layer)
	{
		blend_paint_mask(outs, UV, paint_mask, smooth_paint_mask);
	}
	blend_grime(outs, paint_mask, smooth_paint_mask);

	outs.albedo *= exposure;

#ifdef BAKE_MODE
	vec3 out_color = vec3(0.0);
	switch (bake_target)
	{
		case 0: out_color = outs.albedo; break;
		case 1: out_color = vec3(outs.metallic, outs.roughness, 0.0); break;
		case 2: out_color = outs.normal; break;
	}
	ALBEDO = out_color;
#else
	ALBEDO = outs.albedo;
	METALLIC = outs.metallic;
	ROUGHNESS = outs.roughness;
	NORMAL_MAP = outs.normal;
#endif
}

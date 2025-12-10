#include "pma_header.gdshaderinc"
#include "voronoi_fbm.gdshaderinc"

// Struct for compact value passing of the wear, pit and detail masks.
struct maskset
{
	float wear_mask;
	float pit_mask;
	float detail_mask;
};

// Samples the detail mask at the given position.
// Does not use a seed because the difference would be unnoticable.
//
// The detail mask is used to add high frequency detail to other mask textures.
// The value is between 0.0 and 1.0
float get_detail_mask(vec3 pos, float lod)
{
	float mask = snoise_fbm(pos*detail_scale, int(detail_fbm_iterations));
	mask = mask * 0.5 + 0.5; // Remap around 0.0-1.0
	float w = clamp(0.5 + lod, 0.0, 1.0); // Stronger flattening when far away
	return mix(mask, 0.5, w); // Flatten around 0.5
}

// Samples the pit mask at the given position.
// Uses seed_f for rng.
//
// The pit mask is used as pitting corrosion and as part of the paint wear mask.
// The value is between -0.25 and 1.0
float get_pit_mask(vec3 pos, float seed_f)
{
	float mask = 1.0 - voronoi_fbm(pos*pit_scale, seed_f, int(pit_fbm_iterations));

	// Clamped between -0.25 and 1.0 to allow for some wear "slowing"
	// at negative positions without being strong enough to allow for spots
	// to stay unworn for too long (e.g., pristine spots after strong uniform corrosion).
	return clamp(mask, -0.25, 1.0);
}

// Samples the wear mask at the given position.
// Uses seed_f for rng.
//
// The wear mask is used to scale the strength of the wear effects differently
// across space. The value is between 0.0 and 1.0
float get_wear_mask(vec3 pos, float seed_f)
{
	return voronoi3d_sq(pos*wear_scale, seed_f);
}

// Samples the value of the rust mask at the given position.
// - weathering_intensity defines how strongly the mask is aged
// - mask_set contains the wear, pit and detail masks to be blended in
// - makes use of some uniforms that are not passed as parameters
//
// Returns a value between 0.0 and 1.0
float get_rust_mask(float weathering_intensity, maskset mask_set)
{
	const float uv_uniform_factor = 2.0; // UV/heat should visibly speed up uniform corrosion
	float min_rust = exp(weathering_intensity) // Use a global minimum rust amount as uniform corrosion
		* uniform_corrosion_speed
		* (1.0 + mask_set.pit_mask) // Have uniform corrosion still favor pits
		* (1.0 + uv_and_heat * uv_uniform_factor);

	float wear = max(min_rust, mask_set.wear_mask);
	float pits = max(min_rust, mask_set.pit_mask);
	float detail = mask_set.detail_mask; // No min_rust here to avoid fully flat corrosion

	float value = wear * pits * detail;
	return clamp(value * weathering_intensity, 0.0, 1.0);
}

// Samples the value of the paint mask at the given position.
// - weathering_intensity defines how strongly the mask is aged
// - mask_set contains the wear, pit and detail masks to be blended in
// - seed_f is used for rng
// - makes use of some uniforms that are not passed as parameters
//
// Returns a value between 0.0 (Paint fully intact) and 1.0 (Paint fully gone)
float get_paint_mask(vec3 pos, float weathering_intensity, maskset mask_set, float seed_f)
{
	// These scales and weights are hard-coded so other aging effects
	// do not need to dynamically depend on this weight distribution.
	// I also want to avoid parameter-choice paralysis.
	const float w1 = 0.8;
	const float w2 = 0.6;
	const float w3 = 0.6;
	const float w4 = 0.2;
	const float scale_2 = 2.0;

	float m1 = dist_from_voronoi3d_border(pos * patch_scale, seed_f);
	float m2 = dist_from_voronoi3d_border(pos * patch_scale * scale_2, seed_f);
	float m3 = mask_set.pit_mask;
	float m4 = mask_set.detail_mask;
	float value = m1*w1 + m2*w2 + m3*w3 + m4*w4;

	// Introduce a larger wear mask that increases in weight over time
	// to reduce the border-banding of the other layers at later stages.
	value += mask_set.wear_mask * weathering_intensity;
	value += uniform_corrosion_speed * exp(weathering_intensity);

	return clamp(value * weathering_intensity, 0.0, 1.0);
}
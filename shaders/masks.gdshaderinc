#include "voronoi.gdshaderinc"
#include "snoise3d.gdshaderinc"

// Allows using the uniforms of the shader that this is included into
// without leaving this standalone file with errors.
// -> Whichever file includes this one needs to define INCLUDE_PARAMS_DEFINED
#ifndef INCLUDE_PARAMS_DEFINED
	uniform float patch_scale;
	uniform float wear_scale;
	uniform float detail_scale;
	uniform float age;
	uniform float time_scale;
	uniform float uv_and_heat;
	uniform float pollution;
	uniform float moisture;
	uniform float mechanical_load;
	uniform float uniform_corrosion_speed;
#endif

// Struct for compact value passing of the wear, pit and detail masks.
struct maskset
{
	float wear_mask;
	float pit_mask;
	float detail_mask;
};

float voronoi_fbm(vec3 pos)
{
	const int iterations = 5;
	const float hurst = exp2(-0.5);

	float value = 0.0;
	float amplitude = 1.0;
	float frequency = 1.0;
	for(int i = 0; i < iterations; ++i)
	{
		value += amplitude * voronoi3d_sq(frequency * pos);
		amplitude *= hurst;
		frequency *= 2.0;
	}

	return value;
}

float snoise_fbm(vec3 pos)
{
	const int iterations = 4;
	const float hurst = exp2(-0.5);

	float value = 0.0;
	float amplitude = 1.0;
	float frequency = 1.0;
	for(int i = 0; i < iterations; ++i)
	{
		value += amplitude * snoise(frequency * pos);
		amplitude *= hurst;
		frequency *= 2.0;
	}

	return value;
}

float get_detail_mask(vec3 pos, float lod)
{
	float mask = snoise_fbm(pos*detail_scale);
	mask = (mask * 0.5) + 0.5; // Remap to 0.0-1.0
	return mix(mask, 0.5, clamp(0.5 + lod, 0.0, 1.0)); // Flatten around 0.5
}

float get_pit_mask(vec3 pos)
{
	return clamp(1.0 - voronoi_fbm(pos*patch_scale*3.0 *(0.75+mechanical_load)), 0.0, 1.0);
}

float get_wear_mask(vec3 pos)
{
	return voronoi3d_sq(pos*wear_scale);
}

// Samples the value of the rust mask at the given position.
// - strength defines how strongly the mask is aged
// - mask_set contains the wear, pit and detail masks to be blended in
// - makes use of some uniforms that are not passed as parameters
//
// Returns a value around 0.0 and 1.0 which can go beyond 1.0 for strong rust wear.
float rust_mask(float strength, maskset mask_set)
{
	const float uv_uniform_factor = 2.0; // UV/heat should visibly speed up uniform corrosion
	float min_rust = exp(strength) // Use a global minimum rust amount as uniform corrosion
		* uniform_corrosion_speed
		* (1.0 + mask_set.pit_mask) // Have uniform corrosion still favor pits
		* (1.0 + uv_and_heat * uv_uniform_factor);

	float wear = max(min_rust, mask_set.wear_mask);
	float pits = max(min_rust, mask_set.pit_mask);
	float detail = mask_set.detail_mask; // No min_rust here to avoid fully flat corrosion

	float value = wear * pits * detail;
	return value * strength;
}

// Samples the value of the paint mask at the given position.
// - strength defines how strongly the mask is aged
// - mask_set contains the wear, pit and detail masks to be blended in
// - makes use of some uniforms that are not passed as parameters
//
// Returns a value between 0.0 (Paint fully intact) and 1.0 (Paint fully gone)
float paint_mask(vec3 pos, float strength, maskset mask_set)
{
	// These weights are hard-coded so other aging effects
	// do not need to dynamically depend on this weight distribution.
	// I also want to avoid parameter-choice paralysis.
	const float w1 = 0.8;
	const float w2 = 0.6;
	const float w3 = 0.6;
	const float w4 = 0.2;

	// Similar reason for these scale factors to be kept constant.
	const float s1 = 2.0;
	const float s2 = 4.0;

	float p1 = dist_from_voronoi3d_border(pos * patch_scale * s1);
	float p2 = dist_from_voronoi3d_border(pos * patch_scale * s2);
	float p3 = mask_set.pit_mask;
	float p4 = mask_set.detail_mask;
	float value = p1*w1 + p2*w2 + p3*w3 + p4*w4;

	// Introduce a larger wear mask that increases in weight over time
	// to reduce the border-banding of the other layers at later stages.
	value += mask_set.wear_mask * strength;
	value += uniform_corrosion_speed * exp(strength);

	return clamp(value * strength, 0.0, 1.0);
}
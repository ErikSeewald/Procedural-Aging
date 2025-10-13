#include "voronoi.gdshaderinc"
#include "snoise3d.gdshaderinc"

// Allows using the uniforms of the shader that this is included into
// without leaving this standalone file with errors.
// -> Whichever file includes this one needs to define INCLUDE_PARAMS_DEFINED
#ifndef INCLUDE_PARAMS_DEFINED
	uniform float patch_scale;
	uniform float pitting_factor;
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

float adjust_aging_speed(float vertex_weight)
{
	return (moisture + mechanical_load + uv_and_heat * 0.75 + pollution * 0.25)
	* (1.0 + vertex_weight) * age * time_scale;
}

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

float get_detail_mask(vec3 pos)
{
	float mask = snoise_fbm(pos*detail_scale);
	mask = (mask * 0.5) + 0.5; // Remap to 0.0-1.0
	return mix(mask, 0.5, 0.5); // Flatten around 0.5
}

float get_pit_mask(vec3 pos)
{
	return 1.0 - voronoi_fbm(pos*patch_scale*3.0);
}

float get_wear_mask(vec3 pos)
{
	return voronoi3d_sq(pos*pitting_factor);
}

// Returns a value focused on but able to go beyond the range of 0.0 to 1.0
float rust_mask(vec3 pos, float vertex_weight, maskset mask_set, float detail_factor)
{
	float adjusted_speed = adjust_aging_speed(vertex_weight);

	float min_rust = exp(adjusted_speed) * uniform_corrosion_speed * (1.0 + mask_set.pit_mask);

	float patches = max(min_rust, mask_set.wear_mask);
	float pits = max(min_rust, mask_set.pit_mask);
	float detail = mask_set.detail_mask + (1.0 - detail_factor);

	float value = patches * pits * detail;
	return value * adjusted_speed;
}

// Samples the value of the paint mask at the given position.
// - vertex_weight allows using vertex paint to make specific areas of the mesh age more
//  intensely
// - mask_set contains the wear, pit and detail masks to be blended in
// - makes use of some uniforms that are not passed as parameters
//
// Returns a value between 0.0 (Paint fully intact) and 1.0 (Paint fully gone)
float paint_mask(vec3 pos, float vertex_weight, maskset mask_set)
{
	float adjusted_speed = adjust_aging_speed(vertex_weight);

	// These weights are hard-coded so other aging effects
	// do not need to dynamically depend on this weight distribution.
	// I also want to avoid parameter-choice paralysis.
	const float w1 = 0.8;
	const float w2 = 0.6;
	const float w3 = 0.6;
	const float w4 = 0.2;

	// Similar reason for these scale factors to be kept constant
	const float s1 = 2.0;
	const float s2 = 4.0;

	float p1 = dist_from_voronoi3d_border(pos * patch_scale * s1);
	float p2 = dist_from_voronoi3d_border(pos * patch_scale * s2);
	float p3 = mask_set.pit_mask;
	float p4 = mask_set.detail_mask;
	float value = p1*w1 + p2*w2 + p3*w3 + p4*w4;

	// Introduce a larger wear mask that increases in weight over time
	// to reduce the border-banding of the other layers at later stages
	value += mask_set.wear_mask * adjusted_speed;

	return clamp(value * adjusted_speed, 0.0, 1.0);
}
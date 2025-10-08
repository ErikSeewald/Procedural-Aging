#include "voronoi.gdshaderinc"

// Allows using the uniforms of the shader that this is included into
// without leaving this standalone file with errors.
// -> Whichever file includes this one needs to define INCLUDE_PARAMS_DEFINED
#ifndef INCLUDE_PARAMS_DEFINED
	uniform float patch_scale;
	uniform float detail_scale;
	uniform float age;
	uniform float time_scale;
	uniform float uv_and_heat;
	uniform float pollution;
	uniform float moisture;
	uniform float mechanical_load;
	uniform float rust_mask_scale;
#endif

float adjust_aging_speed(float vertex_weight)
{
	return (moisture + mechanical_load + uv_and_heat * 0.75 + pollution * 0.25)
	* (1.0 + vertex_weight) * age * time_scale;
}

float rust_mask(vec3 pos, float detail_factor, float vertex_weight)
{
	float v1 = 1.0 - voronoi3d_sq(pos*rust_mask_scale);
	float v2 = 1.0 - voronoi3d_sq(pos*rust_mask_scale*2.0); // More disorder in how many points appear first
	float v = v1*v2* log(1.0 + age * time_scale) * 10.0; // Exponential "point" spawn falloff

	// This is supposed to mimic picking a set of random points and having more of them appear
	// over time with an exponential falloff.
	// By intensifying the voronoi pattern and choosing a cutoff point, a growing "closeness"
	// to the original points can be mimicked because not all voronoi points reach the cutoff
	// at the same time.

	float f = pos.y * 2.0; // f will be whatever growth function is used by the "points"

	return v > 0.5 ? f : 0.0;
}

// Samples the value of the paint mask at the given position.
// - detail_factor allows scaling the weights of the detail layers
//	to reduce aliasing. (The factor is clamped between 0.0 and 1.0 before use)
// - vertex_weight allows using vertex paint to make specific areas of the mesh age more
//  intensely
//
// Returns a value between 0.0 (Paint fully intact) and 1.0 (Paint fully gone)
float paint_mask(vec3 pos, float detail_factor, float vertex_weight)
{
	float adjusted_speed = adjust_aging_speed(vertex_weight);

	float size_1 = patch_scale * 2.0;
	float size_2 = patch_scale * 4.0;
	float size_3 = patch_scale * 16.0;
	float size_4 = detail_scale * 256.0;
	float size_5 = detail_scale * 512.0;

	// These weights are hard-coded so other aging effects
	// do not need to dynamically depend on this weight distribution.
	// I also want to avoid parameter-choice paralysis.
	const float w1 = 0.8;
	const float w2 = 0.6;
	const float w3 = 0.2;

	const float detail_weight = 0.3;
	const float base_detail_factor = 2.0; // The base detail should wear down slower
	detail_factor = clamp(detail_factor, 0.0, 1.0);
	float w4 = detail_weight * min(detail_factor * base_detail_factor, 1.0);
	float w5 = detail_weight * detail_factor;

	// Sample values based on distance to vornoi borders for each size
	// and blend them together.
	float d1 = dist_from_voronoi3d_border(pos * size_1);
	float d2 = dist_from_voronoi3d_border(pos * size_2);
	float d3 = dist_from_voronoi3d_border(pos * size_3);
	float d4 = dist_from_voronoi3d_border(pos * size_4);
	float d5 = dist_from_voronoi3d_border(pos * size_5);

	float value = d1*w1 + d2*w2 + d3*w3 + d4*w4 + d5*w5;

	// Introduce a larger wear mask that increases in weight over time
	// to reduce the border-banding of the other layers at later stages
	const float wear_size = 2.0;
	vec2 wear_values = voronoi3d_closest_sq(pos * wear_size);
	float wear = wear_values.x + wear_values.y;
	value += wear*adjusted_speed;

	return clamp(value * adjusted_speed, 0.0, 1.0);
}

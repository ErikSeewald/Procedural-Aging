#include "snoise3d.gdshaderinc"

const float hurst = exp2(-0.5); // fbm hurst exponent

// Voronoi3d neighbors
const int NUM_NEIGHBORS = 27;
const vec3 NEIGHBOR_OFFSETS[NUM_NEIGHBORS] = vec3[](
	vec3(-1.0, -1.0, -1.0), vec3(0.0, -1.0, -1.0), vec3(1.0, -1.0, -1.0),
	vec3(-1.0,  0.0, -1.0), vec3(0.0,  0.0, -1.0), vec3(1.0,  0.0, -1.0),
	vec3(-1.0,  1.0, -1.0), vec3(0.0,  1.0, -1.0), vec3(1.0,  1.0, -1.0),

	vec3(-1.0, -1.0,  0.0), vec3(0.0, -1.0,  0.0), vec3(1.0, -1.0,  0.0),
	vec3(-1.0,  0.0,  0.0), vec3(0.0,  0.0,  0.0), vec3(1.0,  0.0,  0.0),
	vec3(-1.0,  1.0,  0.0), vec3(0.0,  1.0,  0.0), vec3(1.0,  1.0,  0.0),

	vec3(-1.0, -1.0,  1.0), vec3(0.0, -1.0,  1.0), vec3(1.0, -1.0,  1.0),
	vec3(-1.0,  0.0,  1.0), vec3(0.0,  0.0,  1.0), vec3(1.0,  0.0,  1.0),
	vec3(-1.0,  1.0,  1.0), vec3(0.0,  1.0,  1.0), vec3(1.0,  1.0,  1.0)
);

// 3d vector hash function that uses the seed uniform.
// Specifically made for voronoi. May have artifacts when used for other noise.
vec3 voronoi_hash3d(vec3 p, float seed_f)
{
	const vec3 c0 = vec3(123.4, 567.8, 12.3);
	const vec3 c1 = vec3(456.7, 80.1, 234.5);
	const vec3 c2 = vec3(678.9, 987.6, 543.2);

	float f0 = dot(p, c0) + seed_f;
	float f1 = dot(p, c1) + seed_f;
	float f2 = dot(p, c2) + seed_f;

	const float spread_factor = 5678.9123;
	vec3 v = sin(vec3(f0, f1, f2))  * spread_factor;
	return fract(v);
}

// Returns the squared distance from the given cell position with its fractional
// part and the cell center of the neighbor defined by the given offset.
float voronoi3d_neighbor_dist_sq(ivec3 cell_pos, vec3 cell_fract, vec3 offset, float seed_f)
{
	vec3 neighbor_cell = vec3(cell_pos) + offset;
	vec3 jitter = voronoi_hash3d(neighbor_cell, seed_f);
	vec3 delta = offset + jitter - cell_fract;
	return dot(delta, delta);
}

// Returns the squared distance to the closest voronoi cell center.
// Uses the given float seed for rng.
float voronoi3d_sq(vec3 pos, float seed_f)
{
	ivec3 cell_pos = ivec3(floor(pos));
	vec3 frac = fract(pos);
	float min_dist = 1e9;

	for (int i = 0; i < NUM_NEIGHBORS; ++i)
	{
		vec3 offset = NEIGHBOR_OFFSETS[i];
		float distSq = voronoi3d_neighbor_dist_sq(cell_pos, frac, offset, seed_f);
		if(distSq < min_dist)  { min_dist = distSq; }
	}

	return min_dist;
}


// Returns the squared distances to the closest and second closest cell centers.
// Scales the input position based on the given scale parameter.
// Uses the given float seed for rng.
vec2 voronoi3d_closest_sq(vec3 pos, float seed_f)
{
	ivec3 cell_pos = ivec3(floor(pos));
	vec3 frac = fract(pos);
	vec2 distances = vec2(1e9);

	for (int i = 0; i < NUM_NEIGHBORS; ++i)
	{
		vec3 offset = NEIGHBOR_OFFSETS[i];
		float distSq = voronoi3d_neighbor_dist_sq(cell_pos, frac, offset, seed_f);
		if(distSq < distances.x)
		{
			distances.y = distances.x;
			distances.x = distSq;
		}
		else if(distSq < distances.y)
		{ distances.y = distSq; }
	}

	return distances;
}

// Returns the distance to the closest voronoi cell border.
// 0.0 -> directly on a border.
// Uses the given float seed for rng.
float dist_from_voronoi3d_border(vec3 pos, float seed_f)
{
    vec2 distances = voronoi3d_closest_sq(pos, seed_f);
    return distances.y - distances.x;
}

// Returns fbm of the given position with voronoi3d_sq as the noise function.
// Uses the given float seed for rng.
float voronoi_fbm(vec3 pos, float seed_f, int iterations)
{
	float value = 0.0;
	float amplitude = 1.0;
	float frequency = 1.0;
	for(int i = 0; i < iterations; ++i)
	{
		value += amplitude * voronoi3d_sq(frequency * pos, seed_f);
		amplitude *= hurst;
		frequency *= 2.0;
	}

	return value;
}

// Returns fbm of the given position with snoise3d as the noise function.
// Uses no seed because snoise fbm is only ever used at small enough scales
// for seed differences not to be noticable.
float snoise_fbm(vec3 pos, int iterations)
{
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
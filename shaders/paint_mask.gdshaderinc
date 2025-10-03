// Allows using the uniforms of the shader that this is included into
// without leaving this standalone file with errors.
// -> Whichever file includes this one needs to define INCLUDE_PARAMS_DEFINED
#ifndef INCLUDE_PARAMS_DEFINED
	uniform uint patch_size;
	uniform uint detail_size;
	uniform float age;
	uniform float time_scale;
	uniform uint seed;
	uniform float uv_intensity;
#endif

vec2 hash2D(ivec2 p)
{
    uvec2 q = uvec2(p) ^ uvec2(seed);
    q = 1103515245U * ((q >> 1U) ^ (q.yx));
    uint n = 1103515245U * (q.x ^ (q.y>>3u));
    uint m = 1103515245U * (q.y ^ (q.x>>3u));
    return vec2(float(n), float(m)) * (1.0 / 4294967296.0);
}

// Returns the the positive value of a % m
ivec2 imodp(ivec2 a, int m)
{
	return ivec2(((a.x % m) + m) % m, ((a.y % m) + m) % m);
}

// Returns the squared distances to the closest and second closest cell center.bool
// Tiles and scales based on the given scale paarameter.
vec2 voronoi_sq_tiled(vec2 pos, uint scale)
{
	pos = (pos*float(scale)) / float(scale);
	ivec2 cell_pos = ivec2(pos);
    vec2 frac = fract(pos);

    vec2 distances = vec2(1e9);
    for(int y=-1; y<=1; ++y)
	{
		for(int x=-1; x<=1; ++x)
		{
			ivec2 neighbor_cell = imodp(cell_pos + ivec2(x, y), int(scale));
			vec2 jitter = hash2D(neighbor_cell);

			vec2 delta = vec2(float(x), float(y)) + jitter - frac;
			float distSq = dot(delta, delta);

			if(distSq < distances.x)
			{
				distances.y = distances.x;
				distances.x = distSq;
			}

			else if(distSq < distances.y)
			{
				distances.y = distSq;
			}
		}
	}

    return distances;
}


// Returns the distance from one of the voronoi borders.
// Is 0 directly on a border.
float dist_from_border_tiled(vec2 pos, uint scale)
{
    vec2 distances = voronoi_sq_tiled(pos * float(scale), scale);
    return distances.y - distances.x;
}

// Samples the value of the paint mask based on the given parameters.
//
// Returns a value between 0.0 (Paint fully intact) and 1.0 (Paint fully gone)
float paint_mask(vec2 uv)
{
	// Tiling works best if the cell sizes are powers of 2.
	uint size_1 = patch_size * 4u;
	uint size_2 = patch_size * 8u;
	uint size_3 = patch_size * 32u;
	uint size_4 = detail_size * 256u;
	uint size_5 = detail_size * 512u;

	// These weights are hard-coded so other aging effects
	// do not need to dynamically depend on this weight distribution.
	// I also want to avoid parameter-choice paralysis.
	const float w1 = 0.8;
	const float w2 = 0.6;
	const float w3 = 0.2;
	const float w4 = 0.3;
	const float w5 = 0.3;

	// Sample values based on distance to vornoi borders for each size
	// and blend them together.
	float d1 = dist_from_border_tiled(uv, size_1);
	float d2 = dist_from_border_tiled(uv, size_2);
	float d3 = dist_from_border_tiled(uv, size_3);
	float d4 = dist_from_border_tiled(uv, size_4);
	float d5 = dist_from_border_tiled(uv, size_5);

	float value = d1*w1 + d2*w2 + d3*w3 + d4*w4 + d5*w5;
	float env_factor = uv_intensity/100.0;
	return clamp(value * age * time_scale * env_factor, 0.0, 1.0);
}
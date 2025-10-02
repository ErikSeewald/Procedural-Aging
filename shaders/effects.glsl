#[compute]
#version 450

// 8x8 tiles
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Output
layout(set = 0, binding = 0, rgba8)
uniform writeonly image2D OUT_IMG;

layout(push_constant) uniform Params {
	vec4 instanceColor;
	float age;
	float temperature;
	uint patch_size;
	float time_scale;
} pc;

// RNG
float seed;

vec2 hash2D(ivec2 p) 
{
    uvec2 q = uvec2(p) ^ uvec2(seed, seed);
    q = 1103515245U * ((q >> 1U) ^ (q.yx));
    uint n = 1103515245U * (q.x ^ (q.y>>3));
    uint m = 1103515245U * (q.y ^ (q.x>>3));
    return vec2(n, m) * (1.0 / 4294967296.0);
}

// Positive mod m
ivec2 imodp(ivec2 a, uint m)
{
	return ivec2(((a.x % m) + m) % m, ((a.y % m) + m) % m);
}

// Returns the squared distances to the closest and second closest cell center
vec2 voronoi_sq_tiled(vec2 pos, uint period)
{
	pos = fract(pos / float(period)) * float(period);
	ivec2 cell_pos = ivec2(floor(pos));
    vec2 frac = fract(pos);

    vec2 distances = vec2(1e9);
    for(int y=-1; y<=1; ++y)
	{
		for(int x=-1; x<=1; ++x)
		{
			ivec2 ncell = imodp(cell_pos + ivec2(x, y), period);
			vec2 jitter = hash2D(ncell);

			vec2 delta = vec2(x, y) + jitter - frac;
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
float dist_from_border_tiled(vec2 pos, uint period)
{
    vec2 distances = voronoi_sq_tiled(pos * float(period), period);
    return distances.y - distances.x;;
}

// Samples the value of the paint mask based on the given parameters.
// - The given patch size determines the size of the 'paint wear patches'.
//
// Returns a value between 0.0 (Paint fully intact) and 1.0 (Paint fully gone)
float paint_mask(vec2 uv, ivec2 dims, float age, uint patch_size)
{
	// Tiling works best if the cell sizes are powers of 2.
	// The size_1 and size_2 are in fixed relation to create patches.
	// size_3 is hard-coded to be half output resolution to add detail.
	const uint size_1 = patch_size * 4;
	const uint size_2 = patch_size * 8;
	const uint size_3 = dims.x >> 1;

	// These weights are hard-coded so other aging effects 
	// do not need to dynamically depend on this weight distribution.
	// I also want to avoid parameter-choice paralysis.
	const float w1 = 0.8;
	const float w2 = 0.6;
	const float w3 = 0.5;

	// Sample values based on distance to vornoi borders for each size
	// and blend them together.
	float d1 = dist_from_border_tiled(uv, size_1);
	float d2 = dist_from_border_tiled(uv, size_2);
	float d3 = dist_from_border_tiled(uv, size_3);

	float value = d1*w1 + d2*w2 + d3*w3;
	return clamp(value * age, 0.0, 1.0);
}

void main()
{
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
	ivec2 dims = imageSize(OUT_IMG).xy;
	if (pos.x >= dims.x || pos.y >= dims.y) { return; }

	vec2 uv = (vec2(pos)) / vec2(dims);
	seed = pc.temperature * pc.instanceColor.r;
	float age = pc.age * pc.time_scale;

	float r = paint_mask(uv, dims, age, pc.patch_size);
	float g = 0.0;
	float b = 0.0;
	float a = 1.0;	
	imageStore(OUT_IMG, pos, vec4(r, g, b, a));
}
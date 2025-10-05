// Allows using the uniforms of the shader that this is included into
// without leaving this standalone file with errors.
// -> Whichever file includes this one needs to define INCLUDE_PARAMS_DEFINED
#ifndef INCLUDE_PARAMS_DEFINED
	uniform uint patch_size;
	uniform uint detail_size;
	uniform float age;
	uniform float time_scale;
	uniform uint seed;
	uniform float uv_and_heat;
	uniform float pollution;
	uniform float moisture;
#endif

vec3 hash3D(vec3 p)
{
	float s = fract(float(seed) / 3.0)*100.0;
	p += s * 0.12345;

	p = vec3(
		dot(p, vec3(127.1, 311.7, 74.7)  + s * 0.1),
		dot(p, vec3(269.5, 183.3, 246.1) + s * 0.2),
		dot(p, vec3(113.5, 271.9, 124.6) + s * 0.3)
		);

	vec3 h = fract(sin(p) * 43758.5453);

	h += dot(h, h.yzx + (19.19 + s * 0.017));
	return fract(h * (0.75 + 0.05 * fract(s * 0.318)));
}

// Returns the squared distances to the closest and second closest cell center.bool
// Tiles and scales based on the given scale paarameter.
vec2 voronoi_sq_tiled(vec3 pos, uint scale)
{
	pos = (pos*float(scale)) / float(scale);
	ivec3 cell_pos = ivec3(floor(pos));
    vec3 frac = fract(pos);

    vec2 distances = vec2(1e9);
	for (int z=-1; z<=1; ++z)
	{
	    for(int y=-1; y<=1; ++y)
		{
			for(int x=-1; x<=1; ++x)
			{
				ivec3 neighbor_cell = cell_pos + ivec3(x, y, z);
				vec3 jitter = hash3D(vec3(neighbor_cell));

				vec3 delta = vec3(float(x), float(y), float(z)) + jitter - frac;
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
	}


    return distances;
}


// Returns the distance from one of the voronoi borders.
// Is 0 directly on a border.
float dist_from_border_tiled(vec3 pos, uint scale)
{
    vec2 distances = voronoi_sq_tiled(pos * float(scale), scale);
    return distances.y - distances.x;
}

float calculate_acceleration()
{
	return 1.0;
	//return (moisture + uv_and_heat * 0.75 + pollution * 0.25);
}

// Samples the value of the paint mask based on the given parameters.
//
// Returns a value between 0.0 (Paint fully intact) and 1.0 (Paint fully gone)
float paint_mask(vec3 pos)
{	
	float acceleration = calculate_acceleration();
	
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
	float d1 = dist_from_border_tiled(pos, size_1);
	float d2 = dist_from_border_tiled(pos, size_2);
	float d3 = dist_from_border_tiled(pos, size_3);
	float d4 = dist_from_border_tiled(pos, size_4);
	float d5 = dist_from_border_tiled(pos, size_5);
	
	float de = dist_from_border_tiled(pos, 2u);

	float value = d1*w1 + d2*w2 + d3*w3 + d4*w4 + d5*w5;
	value += de*age*time_scale*3.0;
	
	return clamp(value * age * time_scale * acceleration, 0.0, 1.0);
}

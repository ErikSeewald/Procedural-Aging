// Allows using the uniforms of the shader that this is included into
// without leaving this standalone file with errors.
// -> Whichever file includes this one needs to define INCLUDE_PARAMS_DEFINED
#ifndef INCLUDE_PARAMS_DEFINED
	uniform float patch_scale;
	uniform float detail_scale;
	uniform float age;
	uniform float time_scale;
	uniform uint seed;
	uniform float uv_and_heat;
	uniform float pollution;
	uniform float moisture;
	uniform float mechanical_load;
#endif

vec3 hash3D(vec3 p)
{
	const vec3 c0 = vec3(127.1, 311.7, 74.7);
	const vec3 c1 = vec3(269.5, 183.3, 246.1);
	const vec3 c2 = vec3(113.5, 271.9, 124.6);
	
	float s = float(seed) / float(0xffffffffu) * 1.0e9;
	float f0 = dot(p, c0) + s * 0.01;
	float f1 = dot(p, c1) + s * 0.02;
	float f2 = dot(p, c2) + s * 0.03;

	vec3 h = fract(sin(vec3(f0, f1, f2)) * 43758.5453);
	return fract(h);
}

// Returns the squared distances to the closest and second closest cell center.bool
// Tiles and scales based on the given scale paarameter.
vec2 voronoi_sq_tiled(vec3 pos, float scale)
{
	pos = pos * scale;
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
float dist_from_border_tiled(vec3 pos, float scale)
{
    vec2 distances = voronoi_sq_tiled(pos, scale);
    return distances.y - distances.x;
}

float adjust_aging_speed(float vertex_weight)
{
	return (moisture + mechanical_load + uv_and_heat * 0.75 + pollution * 0.25)
	* (1.0 + vertex_weight) * age * time_scale;
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
	float d1 = dist_from_border_tiled(pos, size_1);
	float d2 = dist_from_border_tiled(pos, size_2);
	float d3 = dist_from_border_tiled(pos, size_3);
	float d4 = dist_from_border_tiled(pos, size_4);
	float d5 = dist_from_border_tiled(pos, size_5);
	
	float value = d1*w1 + d2*w2 + d3*w3 + d4*w4 + d5*w5;
	
	// Introduce a larger wear mask that increases in weight over time
	// to reduce the border-banding of the other layers at later stages
	const float wear_size = 2.0;
	float wear = voronoi_sq_tiled(pos * wear_size, wear_size).x;
	value += wear*adjusted_speed;
	
	return clamp(value * adjusted_speed, 0.0, 1.0);
}
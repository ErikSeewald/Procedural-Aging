#ifndef INCLUDE_PARAMS_DEFINED
	uniform uint seed;
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

// Returns the squared distance to the closest 3D voronoi center.
// Scales based on the given scale parameter.
// The given chance parameter describes the likelihood of a cell center existing
// at any cell position.
float voronoi3d_sq_chanced(vec3 pos, float scale, float chance, float time)
{
	pos = pos * scale;
	ivec3 cell_pos = ivec3(floor(pos));
	vec3 frac = fract(pos);

	float min_dist = 1e9;
	for (int z=-1; z<=1; ++z)
	{
	    for(int y=-1; y<=1; ++y)
		{
			for(int x=-1; x<=1; ++x)
			{
				ivec3 neighbor_cell = cell_pos + ivec3(x, y, z);
				vec3 jitter = hash3D(vec3(neighbor_cell));
				float cur_dist_from_chance = chance - (fract(jitter.x + jitter.y + jitter.z) + 0.001);
				if (cur_dist_from_chance < 0.0) { continue; }
				vec3 delta = vec3(float(x), float(y), float(z)) + jitter - frac;
				float distSq = dot(delta, delta);
				distSq /= min(time*cur_dist_from_chance*0.1, scale/4.0);

				if(distSq < min_dist)  { min_dist = distSq; }
			}
		}
	}
	
	return min_dist;
}

// Returns the squared distances to the closest and second closest cell center
// Scales based on the given scale parameter.
vec2 voronoi3d_closest_sq(vec3 pos, float scale)
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
				{ distances.y = distSq; }
			}
		}
	}
	
	return distances;
}


// Returns the distance from one of the voronoi borders.
// Is 0 directly on a border.
float dist_from_voronoi3d_border(vec3 pos, float scale)
{
    vec2 distances = voronoi3d_closest_sq(pos, scale);
    return distances.y - distances.x;
}

#ifndef INCLUDE_PARAMS_DEFINED
	uniform uint seed;
#endif

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

// Returns the squared distance from the given cell position with its fractional
// part and the cell center of the neighbor defined by the given offset.
float voronoi3d_neighbor_dist_sq(ivec3 cell_pos, vec3 cell_fract, vec3 offset)
{
	vec3 neighbor_cell = vec3(cell_pos) + offset;
	vec3 jitter = hash3D(neighbor_cell);
	vec3 delta = offset + jitter - cell_fract;
	return dot(delta, delta);
}

// Returns the squared distance to the closest voronoi cell center.
float voronoi3d_sq(vec3 pos)
{
	ivec3 cell_pos = ivec3(floor(pos));
	vec3 frac = fract(pos);
	float min_dist = 1e9;
	
	for (int i = 0; i < NUM_NEIGHBORS; ++i)
	{
		vec3 offset = NEIGHBOR_OFFSETS[i];
		float distSq = voronoi3d_neighbor_dist_sq(cell_pos, frac, offset);
		if(distSq < min_dist)  { min_dist = distSq; }	
	}
	
	return min_dist;
}


// Returns the squared distances to the closest and second closest cell centers.
// Scales the input position based on the given scale parameter.
vec2 voronoi3d_closest_sq(vec3 pos)
{
	ivec3 cell_pos = ivec3(floor(pos));
	vec3 frac = fract(pos);
	vec2 distances = vec2(1e9);
	
	for (int i = 0; i < NUM_NEIGHBORS; ++i)
	{
		vec3 offset = NEIGHBOR_OFFSETS[i];
		float distSq = voronoi3d_neighbor_dist_sq(cell_pos, frac, offset);
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
float dist_from_voronoi3d_border(vec3 pos)
{
    vec2 distances = voronoi3d_closest_sq(pos);
    return distances.y - distances.x;
}
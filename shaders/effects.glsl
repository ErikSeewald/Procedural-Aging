#[compute]
#version 450

// 8x8 tiles
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Output
layout(set = 0, binding = 0, rgba8)
uniform writeonly image2DArray OUT_IMG;

layout(push_constant) uniform Params {
	vec4 instanceColor;
	float age;
	float temperature;
	float pA; float p1; float p2; float p3; float pb1; 
	float pb2; float pS; float pT; float pT2;
} pc;

// RNG
float seed;

vec2 hash2D(ivec2 p) 
{
    uvec2 q = uvec2(p);
    q = 1103515245U * ((q >> 1U) ^ (q.yx));
    uint n = 1103515245U * (q.x ^ (q.y>>3));
    uint m = 1103515245U * (q.y ^ (q.x>>3));
    return vec2(n, m) * (1.0 / 4294967296.0);
}

// Positive mod m
ivec2 imodp(ivec2 a, int m)
{
	return ivec2(((a.x % m) + m) % m, ((a.y % m) + m) % m);
}

// Returns the squared distances to the closest and second closest cell center
vec2 voronoi_sq_tiled(vec2 pos, int period)
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
			delta -= round(delta);
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
float dist_from_border_tiled(vec2 pos, int period)
{
    vec2 distances = voronoi_sq_tiled(pos * float(period), period);
    return distances.y - distances.x;;
}

vec4 method1(ivec2 pos, ivec2 dims, float age)
{
	// So much refactoring to do :))))))))))))
	age = pc.pA - age; // Whatever number you need to subtract age from also changes based on the other params
	vec2 uv = (vec2(pos)) / vec2(dims);

	const int P1 = int(pc.p1);
	const int P2 = int(pc.p2);
	const int P3 = int(pc.p3);

	float b1 = dist_from_border_tiled(uv, P1);
	float b2 = dist_from_border_tiled(uv, P2);
	float b3 = dist_from_border_tiled(uv, P3);

	float t = clamp(age * pc.pT, 0.0, 1.0);

	// blend them over time
	float border = b1*pc.pb1 + mix(0.0, b2*pc.pb2, smoothstep(0.0, pc.pS, t));
	border = border + mix(0.0, b3, smoothstep(pc.pS, 1.0, t));
	border = clamp(border*age*pc.pT2, 0.0, 1.0);
		
	float value = 1 - border;

	return vec4(vec3(value), 1.0);
}

void main()
{
	seed = pc.temperature * pc.instanceColor.r;

	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
	ivec2 dims = imageSize(OUT_IMG).xy;
	if (pos.x >= dims.x || pos.y >= dims.y) { return; }
	
	int layer = int(gl_GlobalInvocationID.z);
	vec4 color = vec4(0.0);
	
	switch (layer)
	{
		case 0: color = method1(pos, dims, pc.age); break;
		default: return;
	}
	
	imageStore(OUT_IMG, ivec3(pos, layer), color);
}
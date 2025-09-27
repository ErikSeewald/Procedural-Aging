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
} pc;

// RNG
float seed;

vec2 random2f(ivec2 p) 
{
    float x = fract(sin(dot(vec2(p), vec2(127.1, 311.7))) * 43758.5453 * seed);
    float y = fract(sin(dot(vec2(p), vec2(269.5, 183.3))) * 43758.5453 * seed);
    return vec2(x, y);
}

// Returns the squared distances to the closest and second closest cell center
vec2 voronoi_sq(vec2 pos)
{
	ivec2 cell_pos = ivec2(pos);
    vec2 frac = fract(pos);

    vec2 distances = vec2(10.0);
    for(int y=-1; y<=1; ++y)
	{
		for(int x=-1; x<=1; ++x)
		{
			ivec2 neighbor_pos = ivec2(x, y);
			vec2 delta = vec2(neighbor_pos) + random2f(cell_pos + neighbor_pos) - frac;
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
float dist_from_border(vec2 pos)
{
    vec2 distances = voronoi_sq(pos);
    return distances.y - distances.x;;
}

vec4 layer1(ivec2 pos, ivec2 dims, float age)
{
	vec2 uv = vec2(pos) / vec2(dims);

	float b1 = dist_from_border(uv * 5.0);
	float b2 = dist_from_border(uv * 10.0);
	float b3 = dist_from_border(uv * 20.0);

	float t = clamp(age * 0.01, 0.0, 1.0);

	// blend them over time
	// Here, the "age*0.01", the factors at b1, b2 as well as the "border*age*0.1" all play
	// an important role in the size and shape of the cracks. Test them a bit more.
	float border = b1*0.3 + mix(0.0, b2*0.7, smoothstep(0.0, 0.5, t));
	border = border + mix(0.0, b3, smoothstep(0.5, 1.0, t));
	border = clamp(border*age*0.1, 0.0, 1.0);
		
	return vec4(vec3(border), 1.0);
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
		case 0: color = layer1(pos, dims, pc.age); break;
		default: return;
	}
	
	imageStore(OUT_IMG, ivec3(pos, layer), color);
}
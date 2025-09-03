#[compute]
#version 450

// 8x8 tiles
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Output
layout(set = 0, binding = 0, rgba8)
uniform writeonly image2DArray OUT_IMG;

layout(set = 0, binding = 1, std140)
uniform Params
{
    vec4 instanceColor;
	float age;
};

vec4 layer1(ivec2 pos, ivec2 dims, float age)
{
	float g = fract(3 + float(pos.x ^ pos.y) * 0.001 * age);
	return vec4(g, g, g, 1.0);
}
vec4 layer2(ivec2 pos, ivec2 dims, float age)
{
	return vec4(vec2(pos) * age * 0.1 / (vec2(dims)), dims.x, 1.0);
}

void main()
{
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
	ivec2 dims = imageSize(OUT_IMG).xy;
	if (pos.x >= dims.x || pos.y >= dims.y) { return; }
	
	int layer = int(gl_GlobalInvocationID.z);
	vec4 color = vec4(0.0);
	
	switch (layer)
	{
		case 0: color = instanceColor; break;
		case 1: color = layer1(pos, dims, age); break;
		case 2: color = layer2(pos, dims, age); break;
		default: return;
	}
	
	imageStore(OUT_IMG, ivec3(pos, layer), color);
}
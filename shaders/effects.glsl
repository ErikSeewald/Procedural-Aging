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

vec4 layer1(ivec2 pos, ivec2 dims, float age)
{
	int tile = max(1, min(dims.x, dims.y) / 16);
	ivec2 cell = pos / tile;
	bool isBlack = ((cell.x & 1) == 1) && ((cell.y & 1) == 1);
	return isBlack ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(1.0, 1.0, 1.0, 1.0);
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
		case 0: color = layer1(pos, dims, pc.age); break;
		default: return;
	}
	
	imageStore(OUT_IMG, ivec3(pos, layer), color);
}
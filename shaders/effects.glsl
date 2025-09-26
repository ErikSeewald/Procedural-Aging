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


ivec2 get_seed(float index, ivec2 dims)
{
	float x = fract(sin(index * 12.9898) * 43758.5453);
	float y = fract(sin(index * 78.233) * 12345.6789);
	return ivec2(int(floor(x*float(dims.x))), int(floor(y*float(dims.y))));
}

float attentuateByAngle(vec2 v, float brightness, float d, float sharpness)
{
	const float PI = 3.14159265;
	const float TAU = 6.2831853;

	float ang = atan(v.y, v.x);
	if (ang < 0.0) { ang += TAU;}
	float ideal = d * TAU;

	float diff = abs(ang - ideal);
	diff = min(diff, TAU - diff);
	float t = diff / PI;
	float w = smoothstep(1.0, 0.0, t);
	w = pow(w, sharpness);
	return brightness * mix(1.0, 100.0, w);
}

vec4 layer1(ivec2 pos, ivec2 dims, float age, float temperature)
{
	float b = 0.2;

	for (int i = 0; i < (age/4); ++i)
	{
		ivec2 seed = get_seed(i+temperature, dims);
		float d = distance(vec2(pos), vec2(seed));
		b = clamp(d / dims.x, 0.0, 1.0);
		
		b = attentuateByAngle(vec2(seed-pos), b, (d / dims.x) + fract(age) , 0.4);

		if (b < 0.01 * age) {break;}
	}

	return (b < 0.01 * age) ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(1.0, 1.0, 1.0, 1.0);
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
		case 0: color = layer1(pos, dims, pc.age, pc.temperature); break;
		default: return;
	}
	
	imageStore(OUT_IMG, ivec3(pos, layer), color);
}
shader_type canvas_item;

group_uniforms mask_rect;
uniform float z_offset = 0.0;
uniform bool red = true;
uniform bool green = true;
uniform bool blue = true;

uniform float rH = 0.4;
#include "pm_aging_header.gdshaderinc"
#include "masks.gdshaderinc"

void fragment()
{
	vec3 pos = vec3(UV.x, UV.y, z_offset);
	float patches = 1.0 - voronoi3d_sq(pos*rust_pit_scale);
	float swirl = noise(pattern(pos*rust_pit_scale));

	float r = patches;
	float g = swirl;
	float b = r*r*g* age*time_scale;
	float f = fbm(pos*100.0) / 2.0;
	f = smoothstep(0.45, 1.0, f*b);
	f = f*b;
	if (f < 0.45) { f = 0.0 ; }
	COLOR = vec4(red ? r : 0.0, green ? g : 0.0, blue ? f : 0.0,  1.0);
}
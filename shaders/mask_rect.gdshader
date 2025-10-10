shader_type canvas_item;

group_uniforms mask_rect;
uniform float z_offset = 0.0;
uniform bool red = true;
uniform bool green = true;
uniform bool blue = true;
uniform bool overwrite_all = false;

uniform float rH = 0.4;
#include "pm_aging_header.gdshaderinc"
#include "masks.gdshaderinc"

void fragment()
{
	float min_rust = age * uniform_corrosion_speed;
	vec3 pos = vec3(UV.x, UV.y, z_offset);
	float r = max(min_rust, voronoi3d_sq(pos*pitting_factor));
	float g = max(min_rust, 1.0 - fbm(pos*pit_scale));
	float b = fbm(pos*rust_detail_scale);
	float a = r * g * b;

	if (!overwrite_all)
	{	COLOR = vec4(red ? r : 0.0, green ? g : 0.0, blue ? b : 0.0, 1.0); }
	else { COLOR = vec4(a, a, a, 1.0); }

}
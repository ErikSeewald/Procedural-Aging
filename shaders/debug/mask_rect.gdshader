shader_type canvas_item;

group_uniforms mask_rect;
uniform float z_offset = 0.0;
uniform bool red = true;
uniform bool green = true;
uniform bool blue = true;
uniform bool overwrite_all = false;

#include "../pm_aging_header.gdshaderinc"
#include "../masks.gdshaderinc"

void fragment()
{
	float seed_f = float(seed) / float(0xffffffffu);
	vec3 pos = vec3(UV.x, UV.y, z_offset);
	float v = get_pit_mask(pos, seed_f);
	COLOR = vec4(v > 0.0 ? v : 0.0, v < 0.0 ? abs(v) : 0.0, 0.0, 1.0);
}
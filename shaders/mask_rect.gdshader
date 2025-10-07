shader_type canvas_item;

group_uniforms mask_rect;
uniform float z_offset = 0.0;
#include "pm_aging_header.gdshaderinc"
#include "masks.gdshaderinc"

void fragment()
{
	COLOR = vec4(rust_mask(vec3(UV.x, UV.y, z_offset), 1.0, 0.0), 0.0, 0.0, 1.0);
}
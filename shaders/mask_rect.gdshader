shader_type canvas_item;

group_uniforms mask_rect;
uniform float z_offset = 0.0;
#include "pm_aging_header.gdshaderinc"
#include "paint_mask.gdshaderinc"

void fragment()
{
	COLOR = vec4(paint_mask(vec3(UV.x, UV.y, z_offset), 1.0), 0.0, 0.0, 1.0);
}
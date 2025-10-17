shader_type canvas_item;

group_uniforms mask_rect;
uniform float z_offset = 0.0;
uniform bool red = true;
uniform bool green = true;
uniform bool blue = true;
uniform bool overwrite_all = false;

#include "pm_aging_header.gdshaderinc"
#include "masks.gdshaderinc"

void fragment()
{


}
shader_type canvas_item;
#include "pm_aging_header.gdshaderinc"

void fragment()
{
	COLOR = vec4(paint_mask(UV), 0.0, 0.0, 1.0);
}
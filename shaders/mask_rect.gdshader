shader_type canvas_item;
#include "pm_aging_header.gdshaderinc"

void fragment()
{
	seed = get_seed();
	COLOR = vec4(paint_mask(UV), 0.0, 0.0, 1.0);
}
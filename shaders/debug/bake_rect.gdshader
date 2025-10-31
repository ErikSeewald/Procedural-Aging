shader_type canvas_item;
render_mode unshaded;

uniform sampler2D albedo : source_color;
uniform sampler2D mrs;
uniform sampler2D normal : hint_normal;

uniform int show: hint_range(0u, 2u )= 0u;

void fragment()
{

	switch (show) 
	{
		case 0: COLOR = vec4(texture(albedo, UV).rgb, 1.0); break;
		case 1: COLOR = vec4(texture(mrs, UV).rgb, 1.0); break;
		case 2: COLOR = vec4(texture(normal, UV).rgb, 1.0); break;
	}
}
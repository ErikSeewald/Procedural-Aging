shader_type canvas_item;
render_mode unshaded;

/*
* Used for visiualizing the pma masks on a 2D rect.
* Not really documented as it is purely used for debugging and visualization,
* but I wanted to keep it around so all my graphics can be recreated.
* The basic idea here is to make use of the #include pma uniforms as normal
* and then use the added uniforms to define how to display the various masks.
* There are several uniform groups for different visualization modes that
* become active when the 'display_mode' uniform is set to their group.
*/

group_uniforms mask_rect_main;
uniform float z_offset = 0.0;
uniform int display_mode : hint_enum("detail_mask", "with_vs_without_detail")= 0;

group_uniforms mode_detail_mask;
uniform bool simplex_red = false;
uniform bool sfbm_green = false;
uniform bool detail_mask_blue = false;
uniform float sfbm_strength = 1.0;
uniform int full_mode_detail_mask : hint_enum("color", "full_simplex", "full_sfbm", "full_detail_mask") = 0;

group_uniforms mode_with_vs_without_detail;
uniform int base_mask_for_detail : hint_enum("pit_mask");
uniform bool with_detail = false;

#include "../pm_aging_header.gdshaderinc"
#include "../masks.gdshaderinc"

vec4 mode_detail_mask(vec3 pos)
{
	float lod = 0.0;
	float r = snoise(pos * detail_scale);
	float g = snoise_fbm(pos * detail_scale, int(snoise_fbm_iterations)) * sfbm_strength;
	float b = get_detail_mask(pos, 0.0);

	switch (full_mode_detail_mask)
	{
		case 1: return vec4(r < 0.0 ? -r : 0.0, r > 0.0 ? r : 0.0, 0.0, 1.0);
		case 2: return vec4(g < 0.0 ? -g : 0.0, g > 0.0 ? g : 0.0, 0.0, 1.0);
		case 3: return vec4(b, b, b, 1.0);
		default: return vec4(simplex_red ? r : 0.0, sfbm_green ? g : 0.0, detail_mask_blue ? b : 0.0, 1.0);
	}
}

vec4 mode_with_vs_without_detail(vec3 pos, float seedf)
{

	float m;
	switch (base_mask_for_detail)
	{
		default: m = get_pit_mask(pos, seedf); break;
	}

	float d = get_detail_mask(pos, 0.0);
	float v = with_detail ? m * d : m;
	 return vec4(v, v, v, 1.0);
}

void fragment()
{
	vec3 pos = vec3(UV.x, UV.y, z_offset) * uv_scale;
	float seedf = 2.35435f;

	vec4 color;
	switch (display_mode)
	{
		case 0: color = mode_detail_mask(pos); break;
		case 1: color = mode_with_vs_without_detail(pos, seedf); break;
	}

	COLOR = color;
}
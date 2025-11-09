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
uniform int display_mode : hint_enum("detail_mask", "pit_mask", "wear_mask", "rust_mask", "paint_mask", "with_vs_without_detail")= 0;

group_uniforms mode_detail_mask;
uniform bool simplex_red = false;
uniform bool sfbm_blue = false;
uniform float sfbm_strength = 1.0;
uniform int full_mode_detail_mask : hint_enum("color", "full_simplex", "full_sfbm", "full_detail_mask") = 0;

group_uniforms mode_pit_mask;
uniform bool voronoi_red = false;
uniform bool vfbm_blue = false;
uniform float vfbm_strength = 1.0;
uniform float voronoi_red_strength = 1.0;
uniform bool invert_pit_mask_mode = false;
uniform int full_mode_pit_mask : hint_enum("color", "full_voronoi", "full_vfbm", "full_pit_mask") = 0;

group_uniforms mode_rust_mask;
uniform bool include_wear_rust_output = true;
uniform bool include_pits_rust_output = true;
uniform bool include_detail_rust_output = true;
uniform int full_mode_rust_mask : hint_enum("full_min_rust", "full_wear", "full_pits","full_output") = 0;

group_uniforms mode_paint_mask;
uniform bool include_p1_output = true;
uniform bool include_p2_output = true;
uniform bool include_p3_output = true;
uniform bool include_p4_output = true;
uniform bool include_extra_wear = true;
uniform bool discrete_edge_paint_mask = false;
uniform bool use_standard_voronoi_instead = false;
uniform bool apply_smoothstep = false;
uniform float paint_edge = 0.4;
uniform int full_mode_paint_mask : hint_enum("full_p1", "full_p2", "p1_and_p2", "full_output") = 0;


group_uniforms mode_with_vs_without_detail;
uniform int base_mask_for_detail : hint_enum("pit_mask");
uniform bool with_detail = false;

#include "../pma_header.gdshaderinc"
#include "../masks.gdshaderinc"

vec4 mode_detail_mask(vec3 pos)
{
	float lod = 0.0;
	float r = snoise(pos * detail_scale);
	float b= snoise_fbm(pos * detail_scale, int(detail_fbm_iterations)) * sfbm_strength;
	float d = get_detail_mask(pos, 0.0);

	switch (full_mode_pit_mask)
	{
		case 1: return vec4(r < 0.0 ? -r : 0.0, 0.0, r > 0.0 ? r : 0.0, 1.0);
		case 2: return vec4(b < 0.0 ? -b : 0.0, 0.0, b > 0.0 ? b : 0.0 ,1.0);
		case 3: return vec4(d, d, d, 1.0);
		default: return vec4(simplex_red ? r : 0.0, 0.0, sfbm_blue ? b : 0.0, 1.0);
	}
}

vec4 mode_pit_mask(vec3 pos, float seed_f)
{
	float r = voronoi3d_sq(pos * pit_scale, seed_f);
	float b = voronoi_fbm(pos*pit_scale, seed_f, int(pit_fbm_iterations));
	float p = get_pit_mask(pos, seed_f);

	if (invert_pit_mask_mode)
	{
		r = 1.0 - r;
		b = 1.0 - b;
		p = 1.0 - p;
	}
	r *= voronoi_red_strength;
	b *= vfbm_strength;

	switch (full_mode_pit_mask)
	{
		case 1: return vec4(r < 0.0 ? -r : 0.0, 0.0, r > 0.0 ? r : 0.0, 1.0);
		case 2: return vec4(b < 0.0 ? -b : 0.0, 0.0, b > 0.0 ? b : 0.0 , 1.0);
		case 3: return vec4(p < 0.0 ? -p : 0.0, 0.0, p > 0.0 ? p : 0.0 , 1.0);
		default: return vec4(voronoi_red ? r : 0.0, 0.0, vfbm_blue ? b : 0.0, 1.0);
	}
}

vec4 mode_wear_mask(vec3 pos, float seed_f)
{
	float r = get_wear_mask(pos, seed_f);
	return vec4(r, r, r, 1.0);
}

vec4 mode_rust_mask(vec3 pos, float seed_f)
{
	float pit_mask = get_pit_mask(pos, seed_f);
	float wear_mask = get_wear_mask(pos, seed_f);
	const float uv_uniform_factor = 2.0;
	
	float strength = age;
	float min_rust = exp(strength) * uniform_corrosion_speed
		* (1.0 + pit_mask)
		* (1.0 + uv_and_heat * uv_uniform_factor);
		
	float wear = max(min_rust, wear_mask);
	float pits = max(min_rust, pit_mask);
	
	float value = strength;
	if (include_detail_rust_output) { value *= get_detail_mask(pos, 0.0); }
	if (include_pits_rust_output) {value *= pits; }
	if (include_wear_rust_output) { value *= wear; }
	
	switch (full_mode_rust_mask)
	{
		case 1: return vec4(wear, wear, wear, 1.0);
		case 2: return vec4(pits < 0.0 ? -pits : 0.0, 0.0 ,pits > 0.0 ? pits : 0.0, 1.0);
		case 3: return vec4(value, value, value, 1.0);
		default: return vec4(min_rust, min_rust, min_rust, 1.0);
	}
	
}

vec4 mode_paint_mask(vec3 pos, float seed_f)
{
	float strength = age;
	const float w1 = 0.8;
	const float w2 = 0.6;
	const float w3 = 0.6;
	const float w4 = 0.2;
	const float scale_2 = 2.0;

	float p1, p2;
	if (use_standard_voronoi_instead)
	{
		p1 = voronoi3d_sq(pos * patch_scale, seed_f);
		p2 = voronoi3d_sq(pos * patch_scale * scale_2, seed_f);
	}
	else
	{
		p1 = dist_from_voronoi3d_border(pos * patch_scale, seed_f);
		p2 = dist_from_voronoi3d_border(pos * patch_scale * scale_2, seed_f);
	}

	float p3 = get_pit_mask(pos, seed_f);
	float p4 = get_detail_mask(pos, 0.0);
	
	float value = 0.0;
	if (include_p1_output) { value += p1*w1; }
	if (include_p2_output) { value += p2*w2; }
	if (include_p3_output) { value += p3*w3; }
	if (include_p4_output) { value += p4*w4; }
	if (include_extra_wear) 
	{
		value += get_wear_mask(pos, seed_f) * strength;
		value += uniform_corrosion_speed * exp(strength);
	}
	value *= strength;
	
	if (discrete_edge_paint_mask)
	{
		if (value <= 0.5) {value = 0.0;}
		else if (value >= 0.55) {value = 1.0; }
	}
	
	if (apply_smoothstep)
	{
		float offset = (1.0 - paint_edge_sharpness);
		value = smoothstep(paint_edge - offset, paint_edge + offset, value);
	}
	
	switch (full_mode_paint_mask)
	{
		case 1: return vec4(p2, p2, p2, 1.0);
		case 2: return vec4(p1, 0.0, p2, 1.0);
		case 3: return vec4(value, value, value, 1.0);
		default: return vec4(p1, p1, p1, 1.0);
	}
	
}

vec4 mode_with_vs_without_detail(vec3 pos, float seed_f)
{

	float m;
	switch (base_mask_for_detail)
	{
		default: m = get_pit_mask(pos, seed_f); break;
	}

	float d = get_detail_mask(pos, 0.0);
	float v = with_detail ? m * d : m;
	 return vec4(v, v, v, 1.0);
}

void fragment()
{
	vec3 pos = vec3(UV.x, UV.y, z_offset) * uv_scale;
	const uint wrap = 0x10000u;
	float seed_f = float(seed % wrap);

	vec4 color;
	switch (display_mode)
	{
		case 0: color = mode_detail_mask(pos); break;
		case 1: color = mode_pit_mask(pos, seed_f); break;
		case 2: color = mode_wear_mask(pos, seed_f); break;
		case 3: color = mode_rust_mask(pos, seed_f); break;
		case 4: color = mode_paint_mask(pos, seed_f); break;
		case 5: color = mode_with_vs_without_detail(pos, seed_f); break;
	}

	COLOR = color;
}
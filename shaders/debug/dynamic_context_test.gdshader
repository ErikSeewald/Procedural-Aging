shader_type spatial;

#include "../pm_aging_header.gdshaderinc"
#include "../masks.gdshaderinc"

varying vec3 obj_pos;

void vertex() { obj_pos = VERTEX; }

void fragment()
{
	float seed_f = float(seed) / float(0xffffffffu) * 1.0e7;

	//ALBEDO = vec3(uv_and_heat, pollution, moisture);

	//float a = age * time_scale;
	float a = 1.0;

	float v = get_pit_mask(obj_pos, seed_f) * uv_and_heat * pollution * moisture;
	float r = v * uv_and_heat * a;
	float g = v * pollution * a;
	float b = v * moisture * a;
	const float m = 0.05;
	ALBEDO = vec3(r > m ? r : 0.0, g > m ? g : 0.0 , b > m ? b : 0.0);
}
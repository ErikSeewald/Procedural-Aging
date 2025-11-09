shader_type spatial;

uniform sampler2D albedo : source_color;
uniform sampler2D metallic_roughness;
uniform sampler2D normal : hint_normal;

void fragment()
{
	ALBEDO = texture(albedo, UV).rgb;

	vec3 mr_sample = texture(metallic_roughness, UV).rgb;
	METALLIC = mr_sample.r;
	ROUGHNESS = mr_sample.g;
	
	NORMAL_MAP = texture(normal, UV).rgb;
}
shader_type spatial;

uniform sampler2D albedo : source_color;
uniform sampler2D metallic;
uniform sampler2D roughness : hint_roughness_r;
uniform sampler2D normal : hint_normal;

void vertex() {}

void fragment() 
{
	ALBEDO = texture(albedo, UV).rgb;
	METALLIC = texture(metallic, UV).r;
	ROUGHNESS = texture(roughness, UV).r;
	NORMAL_MAP = texture(normal, UV).rgb;
}
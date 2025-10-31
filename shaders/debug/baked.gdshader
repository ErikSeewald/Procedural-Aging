shader_type spatial;

uniform sampler2D albedo : source_color;
uniform sampler2D mrs;
uniform sampler2D normal : hint_normal;
uniform bool use_normal = false;

void fragment()
{
	ALBEDO = texture(albedo, UV).rgb;

	vec3 mrs_sample = texture(mrs, UV).rgb;
	METALLIC = mrs_sample.r;
	ROUGHNESS = mrs_sample.g;
	SPECULAR = mrs_sample.b;

	if (use_normal) { NORMAL_MAP = texture(normal, UV).rgb; }
}
shader_type spatial;

uniform sampler2DArray masks;
uniform int mask_count = 0;

// Per-layer parameters
const int MAX_LAYERS = 8;
uniform float weight[MAX_LAYERS];

// Base material
uniform sampler2D albedo_base;
uniform sampler2D albedo_paint;
uniform float base_metallic = 0.6;
uniform float base_roughness = 0.3;

// AGE
const float MAX_AGE = 20.0;
uniform float age;

vec3 sample_mask(int layer, vec2 uv)
{
	return texture(masks, vec3(uv, float(layer))).rgb;
}

void fragment()
{
	vec3 base_col = texture(albedo_base, UV).rgb;
	vec3 paint_col = texture(albedo_paint, UV).rgb;
	vec3 albedo = paint_col;
	float metallic = base_metallic;
	float roughness = base_roughness;

	for (int i = 0; i < mask_count; i++)
	{
		float w = clamp(age / MAX_AGE * weight[i], 0.0, 1.0);
		vec3 c = sample_mask(i, UV);
		
		if (i == 0 && c.r > 0.5) {metallic = 0.8; albedo = base_col;}
		else if (i == 0) {roughness = 0.8; metallic = 0.8; SPECULAR = 0.5;}

		//albedo = mix(albedo, base_col, w);
		//metallic = clamp(metallic + c.r * w, 0.0, 1.0); // Red as roughness
		//roughness = clamp(roughness + 0.05 * w, 0.0, 1.0);
	}

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
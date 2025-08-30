shader_type spatial;

// A stack of masks, each layer is a single-channel mask
uniform sampler2DArray masks;
uniform int mask_count = 0;

// Per-layer parameters
const int MAX_LAYERS = 8;
uniform float weight[MAX_LAYERS];

// TODO: Base material inputs
uniform sampler2D albedo_base;
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
	vec3 albedo = base_col;
	float metallic = base_metallic;
	float roughness = base_roughness;

	// Aggregate masks
	float total = 0.0;
	float max_w = 0.00001;
	float max_w_mask = 0.0;
	float sum_w = 0.00001;

	for (int i = 0; i < mask_count; i++)
	{
		float w = age / MAX_AGE * weight[i];
		vec3 c = sample_mask(i, UV);

		albedo = mix(albedo, c, w);
		metallic = clamp(metallic + c.r * w, 0.0, 1.0); // Red as roughness
		roughness = clamp(roughness + 0.05 * w, 0.0, 1.0);
	}

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}

/*
void light() {
	DIFFUSE_LIGHT = vec3(1.0, 1.0, 1.0) * dot(NORMAL, LIGHT);
}*/

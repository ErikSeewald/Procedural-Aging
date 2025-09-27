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
		
		// Use mask's red value as blend weight for now, ignore w until there
		// are more masks again
		c.r = clamp(c.r, 0.2, 1.0);
		c.r -= 0.2;
		
		// Keep mostly in tact paint at higher opacity/weight
		if (c.r > 0.8) {c.r = clamp(c.r + (c.r - 0.8), 0.0, 1.0);}
		
		//if (i == 0 && c.r > 0.5) {metallic = 0.8; albedo = base_col;}
		//else if (i == 0) {roughness = 0.8; metallic = 0.8; SPECULAR = 0.5;}

		albedo = mix(albedo, base_col, c.r);
		roughness = mix(0.8, roughness, c.r);
		
		// White outline/residue around edges of paint
		if (c.r > 0.4) 
		{
			float modif = 0.15 / (c.r - 0.4);
			albedo = clamp(albedo + vec3(modif, modif, modif), 0.0, 1.0);
			
			// Desaturate
			albedo = mix(albedo, vec3((albedo.r + albedo.g + albedo.b) / 3.0), modif);
		}
		//metallic = clamp(metallic + c.r * w, 0.0, 1.0); // Red as roughness
		//roughness = clamp(roughness + 0.05 * w, 0.0, 1.0);
	}

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
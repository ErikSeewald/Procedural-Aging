shader_type spatial;
render_mode specular_schlick_ggx;

uniform float age = 0.0; // UNUSED FOR NOW

group_uniforms compute_masks;
uniform sampler2DArray masks;
uniform float weights[2];

group_uniforms base_layer;
uniform float base_metallic = 0.6;
uniform sampler2D albedo_base;
uniform sampler2D normal_base : hint_normal;
uniform sampler2D roughness_base;

group_uniforms paint_layer;
uniform float paint_metallic = 0.4;
uniform float residue_cutoff = 0.9;
uniform float residue_intensity = 0.75;
uniform float residue_falloff = 1.6;
uniform sampler2D albedo_paint;
uniform sampler2D normal_paint : hint_normal;
uniform sampler2D roughness_paint;

vec3 sample_mask(int layer, vec2 uv)
{
	return texture(masks, vec3(uv, float(layer))).rgb;
}

vec3 adjust_contrast(vec3 color, float factor)
{
	return (color - 0.5) * factor + 0.5;
}

void fragment()
{
	int mask_count = textureSize(masks, 0).z;
	
	vec3 base_col = texture(albedo_base, UV).rgb;
	float base_roughness = texture(roughness_base, UV).r;
	vec3 base_normal = texture(normal_base, UV).rgb;
	
	vec3 paint_col = texture(albedo_paint, UV).rgb;
	float paint_roughness = texture(roughness_paint, UV).r;
	vec3 paint_normal = texture(normal_paint, UV).rgb;
	
	vec3 albedo = paint_col;
	float metallic = paint_metallic;
	float roughness = paint_roughness;
	vec3 normal = paint_normal;

	for (int i = 0; i < mask_count; i++)
	{
		if (i > 0) {break;} // Just layer one for debugging
		float w = sample_mask(i, UV).r * weights[i];

		albedo = mix(albedo, base_col, w);
		roughness = mix(roughness, base_roughness, w);
		metallic = mix(metallic, base_metallic, w);
		normal = mix(normal, base_normal, w);
		
		// Sharpen edges with paint residue
		if (w > 0.4) 
		{
			float t = clamp((residue_cutoff - w) / 0.5, 0.0, 1.0);
			float factor = residue_intensity * t * exp(-residue_falloff * (1.0 - t)); 
			albedo = mix(albedo, clamp(paint_col + vec3(0.5), 0.0, 1.0), factor);
		}
	}

 	// Adjust contrast and reduce brightness because the defaults look awful
	albedo = adjust_contrast(albedo, 1.25) * 0.3;

	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal;
}
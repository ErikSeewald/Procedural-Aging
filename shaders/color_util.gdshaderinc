// Adjusts the contrast of the given color based on the given factor.
vec3 adjust_contrast(vec3 color, float factor)
{
	return (color - 0.5) * factor + 0.5;
}

// Desaturates the given color based on the given factor using
// the luminance formula.
vec3 desaturate(vec3 color, float factor)
{
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), color, factor);
}

// Adjusts contrast and reduces brightness based on the selected rendering mode.
void mode_albedo_adjustment(inout vec3 albedo, bool is_compat_mode)
{
	if (is_compat_mode) { albedo = desaturate(albedo, 0.8) * 0.75; }
	else { albedo = adjust_contrast(albedo, 1.25) * 0.3; }
}
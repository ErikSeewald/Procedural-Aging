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
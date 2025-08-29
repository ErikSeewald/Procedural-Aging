shader_type canvas_item;

uniform sampler2D src_tex;

void fragment()
{
	COLOR = texture(src_tex, UV);
}

/*
void light() {
	DIFFUSE_LIGHT = vec3(1.0, 1.0, 1.0) * dot(NORMAL, LIGHT);
}*/

# Autoload for texture related helper functions.
extends Node

# Creates a 1 pixel wide GradientTexture1D with the given color.
func get_unit_texture(color: Color) -> GradientTexture1D:
	var tex := GradientTexture1D.new()
	tex.width = 1
	tex.gradient = Gradient.new()
	tex.gradient.colors = [color]
	return tex

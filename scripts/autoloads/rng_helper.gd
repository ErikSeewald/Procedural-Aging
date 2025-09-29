# Autoload for RNG helper functions. Mostly used for debugging.
@tool
extends Node

var rng := RandomNumberGenerator.new()

## Returns a randomly generated color with parameters skewed toward
## brighter, more saturated colors.
func random_color() -> Color:
	rng.randomize()
	var hue := rng.randf()
	var sat := rng.randf_range(0.7, 1.0)
	var val := rng.randf_range(0.8, 1.0)
	return Color.from_hsv(hue, sat, val, 1.0)

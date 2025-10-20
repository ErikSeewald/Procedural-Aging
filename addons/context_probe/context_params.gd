class_name ContextParams
extends Resource

# All changes to these export variables should emit the "changed" signal
# so that ContextSamplers can connect to it.

@export_range(0.0, 1.0) var uv_and_heat: float = 0.5:
	set(value):
		uv_and_heat = _set_and_emit(uv_and_heat, value)

@export_range(0.0, 1.0) var pollution: float = 0.5:
	set(value):
		pollution = _set_and_emit(pollution, value)
		
@export_range(0.0, 1.0) var moisture: float = 0.5:
	set(value):
		moisture = _set_and_emit(moisture, value)

## Returns an Array of names of all context params.
## Can be useful for .get(name) and .set(name, value).
func get_param_names() -> Array:
	return get_property_list().filter(
		func(p): return p.usage == 4102).map(func(p): return p.name)

## Writes an interpolation of itself and the target
## parameters based on the given weight (0.0 to 1.0)
## into the given "out" object
func interpolate(target: ContextParams, weight: float, out: ContextParams) -> void:
	for param_name in get_param_names():
		var a = get(param_name)
		var b = target.get(param_name)
		out.set(param_name, lerp(a, b, weight))

## Returns the new value after optionally calling emit_changed()
## if the new value is different from the old value.
func _set_and_emit(old_value, new_value):
	if old_value != new_value:
		emit_changed()
	return new_value
	
	

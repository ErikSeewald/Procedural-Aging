## A set of environment context parameters that emit the "changed" signal
## whenever they are modified so that ContextSamplers can connect to it.

class_name ContextParams
extends Resource

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
	return get_property_list() \
	.filter(func(p): return (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0) \
	.map(func(p): return p.name)

## Returns the new value after optionally calling emit_changed()
## if the new value is different from the old value.
func _set_and_emit(old_value, new_value):
	if old_value != new_value:
		emit_changed()
	return new_value
	
	

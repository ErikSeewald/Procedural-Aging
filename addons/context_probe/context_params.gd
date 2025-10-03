class_name ContextParams
extends Resource

# All changes to these export variables should emit the "changed" signal
# so that ContextSamplers can connect to it.

## Temperature in degrees celsius
@export var temperature: float = 20.0:
	set(value):
		temperature = _set_and_emit(temperature, value)

## Humidity in %
@export_range(0.0, 100.0) var humidity: float = 60:
	set(value):
		humidity = _set_and_emit(humidity, value)

## Precipitation in mm/day
@export var precipitation: float = 1.0:
	set(value):
		precipitation = _set_and_emit(precipitation, value)

## UV intensity in W*m^(-2)
@export var uv_intensity: float = 100.0:
	set(value):
		uv_intensity = _set_and_emit(uv_intensity, value)

## Wind speed in m*s^(-1)
@export var wind_speed: float = 4.0:
	set(value):
		wind_speed = _set_and_emit(wind_speed, value)

## Pollution factor
@export var pollution: float = 0.2:
	set(value):
		pollution = _set_and_emit(pollution, value)

## Salinity in %
@export_range(0.0, 100.0) var salinity: float = 0.02:
	set(value):
		salinity = _set_and_emit(salinity, value)	

## Returns an Array of names of all context params.
## Can be useful for .get(name) and .set(name, value).
func get_param_names() -> Array:
	return get_property_list().filter(
		func(p): return p.usage == 4102).map(func(p): return p.name)

## Returns the new value after optionally calling emit_changed()
## if the new value is different from the old value.
func _set_and_emit(old_value, new_value):
	if old_value != new_value:
		emit_changed()
	return new_value
	
	

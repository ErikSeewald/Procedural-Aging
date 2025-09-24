class_name ContextParams
extends Resource

@export var temperature: float = 10.0:
	set(value):
		if value == temperature:
			return
		temperature = value
		emit_changed()
		
@export var humidity: float = 0.7:
	set(value):
		if value == humidity:
			return
		humidity = value
		emit_changed()

@icon("res://addons/context_probe/sampler_icon.svg")
extends Node3D
class_name ContextSampler

## Only interacts with probes on these layers
@export_flags_3d_physics var probe_mask: int = 1

signal context_changed(current: ContextParams)

var _current_probes: Array[ContextProbe] = []

func _ready() -> void:
	var tracker := Area3D.new()
	tracker.monitoring = true
	tracker.monitorable = false
	tracker.collision_mask = probe_mask
	
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = 0.01
	tracker.add_child(shape)
	add_child(tracker)
	
	tracker.area_entered.connect(_on_area_entered)
	tracker.area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area3D) -> void:
	if area is ContextProbe:
		_current_probes.append(area)
		area.params.changed.connect(_emit_context_changed)
		_emit_context_changed()
		
func _on_area_exited(area: Area3D) -> void:
	if area is ContextProbe and _current_probes.has(area):
		_current_probes.erase(area)
		area.params.changed.disconnect(_emit_context_changed)
		_emit_context_changed()

func _emit_context_changed() -> void:
	context_changed.emit(sample_parameters())

func sample_parameters() -> ContextParams:	
	if _current_probes.is_empty():
		return ContextParams.new()
	
	var temp := 0.0
	var humidity := 0.0
	
	for probe in _current_probes:
		temp += probe.params.temperature
		humidity += probe.params.humidity
		
	var sample := ContextParams.new()
	sample.temperature = temp / _current_probes.size()
	sample.humidity = humidity / _current_probes.size()
	return sample

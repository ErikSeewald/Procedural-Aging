extends Node3D
class_name ContextSampler

@export_flags_3d_physics var probe_mask: int
var _current_probes: Array[ContextProbe] = []

signal parameters_changed(current: ContextParams)
const params_changed_signal = "parameters_changed"

func _ready() -> void:
	var tracker := Area3D.new()
	tracker.collision_layer = 0
	tracker.collision_mask = ContextProbe.probe_collision_layer
	tracker.monitoring = true
	tracker.monitorable = false
	
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = 0.1
	tracker.add_child(shape)
	add_child(tracker)
	
	tracker.area_entered.connect(_on_area_entered)
	tracker.area_exited.connect(_on_area_exited)
	
func _on_area_entered(area: Area3D) -> void:
	if area is ContextProbe:
		_current_probes.append(area)
		area.params.connect("changed", _emit_params_changed)
		_emit_params_changed()
		
func _on_area_exited(area: Area3D) -> void:
	if area is ContextProbe and _current_probes.has(area):
		_current_probes.erase(area)
		area.params.disconnect("changed", _emit_params_changed)
		_emit_params_changed()

func _emit_params_changed() -> void:
	emit_signal(params_changed_signal, sample_parameters())

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

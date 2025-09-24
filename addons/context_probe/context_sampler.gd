extends Node3D
class_name ContextSampler

@export_flags_3d_physics var probe_mask: int
var _probes_to_weights: Dictionary[ContextProbe, float] = {}

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
		_probes_to_weights[area as ContextProbe] = 1.0
		emit_signal(params_changed_signal, sample_parameters())
		
func _on_area_exited(area: Area3D) -> void:
	if area is ContextProbe and _probes_to_weights.has(area):
		_probes_to_weights.erase(area)
		emit_signal(params_changed_signal, sample_parameters())
		
func _physics_process(_delta: float) -> void:
	if _probes_to_weights.is_empty():
		return
	var changed := false
	for probe in _probes_to_weights.keys():
		var w := _compute_weight_for(probe)
		if _probes_to_weights[probe] != w:
			_probes_to_weights[probe] = w
			changed = true
	
	if changed:
		emit_signal(params_changed_signal, sample_parameters())
		
func _compute_weight_for(probe: ContextProbe) -> float:
	var p := probe.global_transform.origin
	var d := global_transform.origin.distance_to(p)
	
	return 1/d

func sample_parameters() -> ContextParams:	
	if _probes_to_weights.is_empty():
		return ContextParams.new()
	
	# Weighted blend
	var total_w := 0.0
	var temp := 0.0
	var humidity := 0.0
	
	for probe: ContextProbe in _probes_to_weights.keys():
		var w := _probes_to_weights[probe]
		if w <= 0.0:
			continue
		total_w += w
		temp += probe.params.temperature * w
		humidity += probe.params.humidity * w
		
	var sample := ContextParams.new()
	if total_w > 0.0:
		sample.temperature = temp / total_w
		sample.humidity = humidity / total_w
	return sample

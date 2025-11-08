extends Control

func set_docks_demo_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/demos/docks.tscn")
		
func set_single_objects_demo_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/demos/single_objects.tscn")

func set_context_demo_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/demos/editor_required/context_demo.tscn")

func set_profiling_root_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/profiling/profiling_main.tscn")

func set_shader_testing_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/testing/shader_testing.tscn")

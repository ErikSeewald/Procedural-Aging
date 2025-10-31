extends MeshInstance3D

@export var bake_material: ShaderMaterial

func _ready() -> void:
	AgeBaker.register(self, bake_material)

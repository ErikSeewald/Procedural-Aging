extends MeshInstance3D

@export var bake_material: ShaderMaterial
@export var result_slot := 0
@export var bake_resolution: Vector2i = Vector2i(2048, 2048)

func _ready() -> void:
	AgeBaker.register(self, bake_material, bake_resolution, result_slot)

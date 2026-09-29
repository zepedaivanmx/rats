class_name Charco extends ZonaAmbiental

@export var hongo_scene: PackedScene
@export var cantidad_hongos: int = 3
@export var radio_anillo: float = 2.2   # el charco mide 1.5 de radio

func _ready() -> void:
	super()
	tipo_de_zona = TipoZona.CHARCO

func _al_completar_gestacion(cadaver: Node3D) -> void:
	cadaver.queue_free()
	if not hongo_scene:
		push_warning("Charco: falta asignar hongo_scene")
		return
	for i in cantidad_hongos:
		var ang := TAU * i / cantidad_hongos + randf_range(-0.3, 0.3)
		var hongo = hongo_scene.instantiate()
		get_tree().current_scene.add_child(hongo)
		hongo.global_position = global_position + Vector3(cos(ang) * radio_anillo, 0.5, sin(ang) * radio_anillo)

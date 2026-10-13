class_name PastoZona extends ZonaAmbiental

@export var escarabajo_scene: PackedScene
@export var cantidad_escarabajos: int = 2
@export var distancia_bosque_profundo: float = 35.0

func _ready() -> void:
	super()
	tipo_de_zona = TipoZona.PASTO

func _al_completar_gestacion(cadaver: Node3D) -> void:
	cadaver.queue_free()
	
	if not escarabajo_scene:
		push_warning("PastoZona: falta asignar escarabajo_scene")
		return
		
	var arbol = get_tree().get_first_node_in_group("CentralTree")
	var centro = arbol.global_position if arbol else Vector3.ZERO
		
	for i in cantidad_escarabajos:
		var escarabajo = escarabajo_scene.instantiate()
		get_tree().current_scene.add_child(escarabajo)
		
		var angulo = randf() * TAU
		var pos_spawn = centro + Vector3(cos(angulo), 0.5, sin(angulo)) * distancia_bosque_profundo
		escarabajo.global_position = pos_spawn
		
		# POO: Orden de navegación hacia el pasto
		if escarabajo.has_method("caminar_hacia"):
			escarabajo.caminar_hacia(self.global_position)

class_name ArenaZona extends ZonaAmbiental

@export var lagarto_scene: PackedScene
@export var cantidad_lagartos: int = 1
@export var distancia_bosque_profundo: float = 35.0

func _ready() -> void:
	super()
	tipo_de_zona = TipoZona.ARENA

func _al_completar_gestacion(cadaver: Node3D) -> void:
	cadaver.queue_free()
	
	if not lagarto_scene:
		push_warning("ArenaZona: falta asignar lagarto_scene")
		return
		
	# Obtenemos la madriguera para usarla como punto central y calcular el borde del bosque
	var arbol = get_tree().get_first_node_in_group("CentralTree")
	var centro = arbol.global_position if arbol else Vector3.ZERO
		
	for i in cantidad_lagartos:
		var lagarto = lagarto_scene.instantiate()
		get_tree().current_scene.add_child(lagarto)
		
		# Aparece en un anillo aleatorio simulando el bosque profundo
		var angulo = randf() * TAU
		var pos_spawn = centro + Vector3(cos(angulo), 0.5, sin(angulo)) * distancia_bosque_profundo
		lagarto.global_position = pos_spawn
		
		# POO: Se utiliza la función base heredada de AliadoBase
		if lagarto.has_method("caminar_hacia"):
			lagarto.caminar_hacia(self.global_position)

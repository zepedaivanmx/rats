class_name Charco extends ZonaAmbiental

@export var escena_hongo: PackedScene
@export var cantidad_por_cadaver: int = 3
@export var radio_generacion: float = 1.5

func _ready() -> void:
	super()
	tipo_de_zona = TipoZona.CHARCO

# Sobrescribimos el método virtual definido en zona_ambiental.gd
func _efecto_charco(cadaver: Node3D) -> void:
	if not escena_hongo:
		print("ADVERTENCIA: No hay escena de hongo asignada en el Inspector del nodo Charco.")
		cadaver.queue_free()
		return
		
	_generar_hongos(cadaver.global_position)
	cadaver.queue_free()

func _generar_hongos(posicion_centro: Vector3) -> void:
	for i in range(cantidad_por_cadaver):
		var nuevo_hongo = escena_hongo.instantiate()
		get_tree().current_scene.add_child(nuevo_hongo)
		
		# Distribución radial aleatoria
		var angulo = randf() * TAU
		var distancia = randf_range(0.5, radio_generacion)
		
		# Offset en Y para que el hongo no quede hundido en el modelo del charco
		var offset = Vector3(cos(angulo) * distancia, 0.2, sin(angulo) * distancia)
		nuevo_hongo.global_position = posicion_centro + offset

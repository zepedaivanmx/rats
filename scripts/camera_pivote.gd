extends Node3D

var rata: Node3D

func _ready() -> void:
	# Esperamos un frame para que la escena cargue por completo
	await get_tree().physics_frame
	# Buscamos a la rata por el grupo
	rata = get_tree().get_first_node_in_group("rats")

func _physics_process(delta: float) -> void:
	if rata:
		# Hacemos que el pivote mire DIRECTAMENTE al centro de la rata, 
		# permitiendo que la cámara se incline hacia abajo.
		look_at(rata.global_position, Vector3.UP)

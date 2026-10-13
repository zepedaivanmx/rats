class_name RaizZona extends ZonaAmbiental

@export var torre_scene: PackedScene # Aquí arrastrarás tu nueva torre.tscn en el inspector

func _ready() -> void:
	super()
	tipo_de_zona = TipoZona.RAICES

func _al_completar_gestacion(cadaver: Node3D) -> void:
	# Guardamos dónde estaba el cadáver para que la torre crezca justo ahí
	var posicion_brote = cadaver.global_position 
	cadaver.queue_free()
	
	if not torre_scene:
		push_warning("RaizZona: falta asignar torre_scene")
		return
		
	# Instanciamos la Raíz Alta (Torre) para que empiece a recibir minerales
	var nueva_torre = torre_scene.instantiate()
	get_tree().current_scene.add_child(nueva_torre)
	nueva_torre.global_position = posicion_brote + Vector3(0, 0.5, 0)
	
	# Destruimos la zona raíz original, ya que el espacio ahora está ocupado por la torre
	queue_free()

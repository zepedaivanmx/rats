class_name Mineral
extends Recolectable

@export var radio_maximo: float = 30.0
@export var radio_minimo: float = 8.0

# POO: Sobrescribimos la inicialización del padre Recolectable
func _inicializar_recolectable() -> void:
	modo_recogida = ModoRecogida.BOCA
	collision_layer = CAPA_RECOLECTABLE
	collision_mask = 1 # Choca con el suelo
	if not is_in_group("mineral"):
		add_to_group("mineral")
	ubicar_aleatoriamente()

func ubicar_aleatoriamente() -> void:
	var angulo = randf() * TAU
	var distancia = randf_range(radio_minimo, radio_maximo)
	global_position = Vector3(cos(angulo) * distancia, 0.5, sin(angulo) * distancia)

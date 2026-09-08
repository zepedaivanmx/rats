extends Recolectable

@export var radio_maximo: float = 30.0
@export var radio_minimo: float = 8.0 

# POO: Sobrescribimos la inicialización del padre en lugar de usar _ready()
func _inicializar_recolectable() -> void:
	if not is_in_group("mineral"):
		add_to_group("mineral")
	ubicar_aleatoriamente()

func ubicar_aleatoriamente() -> void:
	var angulo = randf() * TAU
	var distancia = randf_range(radio_minimo, radio_maximo)
	global_position = Vector3(cos(angulo) * distancia, global_position.y, sin(angulo) * distancia)

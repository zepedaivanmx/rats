extends Node3D # O StaticBody3D

@export var radio_maximo: float = 30.0 # Qué tan lejos del centro puede aparecer
@export var radio_minimo: float = 8.0  # Distancia mínima para que no caiga justo encima del árbol

func _ready() -> void:
	# Apenas nace el mineral, lo cambiamos de posición
	ubicar_aleatoriamente()

func ubicar_aleatoriamente() -> void:
	# 1. Generamos un ángulo aleatorio en radianes (de 0 a 360 grados, que es de 0 a TAU/2PI)
	var angulo = randf() * TAU
	
	# 2. Generamos una distancia aleatoria entre el mínimo y el máximo
	var distancia = randf_range(radio_minimo, radio_maximo)
	
	# 3. Calculamos la nueva posición X y Z usando trigonometría básica
	var nueva_posicion = Vector3(
		cos(angulo) * distancia,
		global_position.y, # Mantenemos su altura Y original (para que no flote ni se hunda)
		sin(angulo) * distancia
	)
	
	# 4. Aplicamos la nueva posición
	global_position = nueva_posicion

func desaparecer():
	# Esta es la función que tu rata llama al morderlo
	queue_free()

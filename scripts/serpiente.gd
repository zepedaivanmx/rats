class_name Ciempies
extends PrimordialFather

@export var radio_deteccion_ciega: float = 3.2
@export var fuerza_arrastre_ciempies: float = 6.5
@export var duracion_aturdimiento: float = 1.5

var direccion_erratica: Vector3 = Vector3.FORWARD
var timer_cambio_rumbo: float = 0.0
var cooldown_aturdir: float = 0.0

func _ready() -> void:
	super()
	if not is_in_group("enemy"):
		add_to_group("enemy")
	speed = 6.5 # Rápido
	max_hp = 90.0 # Resiste más de un colazo
	hp = max_hp
	_elegir_direccion_erratica()

func _mover_y_actuar(delta: float) -> void:
	if cooldown_aturdir > 0.0:
		cooldown_aturdir -= delta
	
	# Si el jugador se acerca demasiado a pesar de que el ciempiés es ciego, lo aturde y arrastra
	if is_instance_valid(rata_objetivo) and is_instance_valid(arbol_objetivo):
		var dist_a_rata := global_position.distance_to(rata_objetivo.global_position)
		if dist_a_rata <= radio_deteccion_ciega:
			if cooldown_aturdir <= 0.0 and rata_objetivo.has_method("aplicar_aturdimiento"):
				rata_objetivo.aplicar_aturdimiento(duracion_aturdimiento)
				cooldown_aturdir = 4.0
			
			var dir_bosque := (rata_objetivo.global_position - arbol_objetivo.global_position).normalized()
			dir_bosque.y = 0.0
			if rata_objetivo.has_method("aplicar_arrastre"):
				rata_objetivo.aplicar_arrastre(dir_bosque * fuerza_arrastre_ciempies)
			velocity.x = dir_bosque.x * fuerza_arrastre_ciempies
			velocity.z = dir_bosque.z * fuerza_arrastre_ciempies
			return
	
	# Movimiento errático sin visión
	timer_cambio_rumbo -= delta
	if timer_cambio_rumbo <= 0.0:
		_elegir_direccion_erratica()
	
	velocity.x = direccion_erratica.x * speed
	velocity.z = direccion_erratica.z * speed

func _elegir_direccion_erratica() -> void:
	var angulo := randf() * TAU
	direccion_erratica = Vector3(cos(angulo), 0.0, sin(angulo)).normalized()
	timer_cambio_rumbo = randf_range(0.8, 2.2)

func ha_sido_empujado() -> void:
	if is_instance_valid(rata_objetivo) and rata_objetivo.has_method("romper_arrastre"):
		rata_objetivo.romper_arrastre()

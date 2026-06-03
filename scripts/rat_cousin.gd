extends CharacterBody3D

# --- ESTADOS DEL PRIMO ---
enum Estado { ESCONDIDA, YENDO_AL_JUGADOR, REGRESANDO }
var estado_actual = Estado.ESCONDIDA

# Parámetros de "Grandote"
@export var velocidad: float = 5.0 # Más lento por su tamaño
@export var fuerza_empuje_pasivo: float = 12.0 # Fuerza para apartar al caminar
@export var fuerza_colazo: float = 45.0 # Fuerza para mandar a volar
@export var radio_colazo: float = 9.0 

var arbol: Node3D
var jugador: Node3D
var timer_salida: Timer

@onready var visual = $MeshInstance3D 
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	visual.visible = false
	await get_tree().physics_frame
	arbol = get_tree().get_first_node_in_group("CentralTree")
	jugador = get_tree().get_first_node_in_group("rats")
	
	timer_salida = Timer.new()
	timer_salida.wait_time = 15.0 # Sale con menos frecuencia
	timer_salida.one_shot = true
	timer_salida.timeout.connect(_on_timer_timeout)
	add_child(timer_salida)
	timer_salida.start()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta

	if estado_actual == Estado.ESCONDIDA:
		return

	if not is_instance_valid(jugador) or not is_instance_valid(arbol):
		return

	var objetivo_pos = Vector3.ZERO

	if estado_actual == Estado.YENDO_AL_JUGADOR:
		objetivo_pos = jugador.global_position
		var distancia_plana = Vector2(global_position.x, global_position.z).distance_to(Vector2(objetivo_pos.x, objetivo_pos.z))
		
		# --- MODIFICACIÓN: APARTAR A OTROS MIENTRAS CAMINA ---
		# Requiere un Area3D hija llamada AreaEmpuje
		# --- MODIFICACIÓN: APARTAR A OTROS MIENTRAS CAMINA ---
		if has_node("AreaEmpuje"):
			for cuerpo in $AreaEmpuje.get_overlapping_bodies():
				if cuerpo != self and (cuerpo is RigidBody3D or cuerpo is CharacterBody3D):
					var dir_empuje = (cuerpo.global_position - global_position).normalized()
					dir_empuje.y = 0.1 # Ligera elevación
					if cuerpo is RigidBody3D:
						cuerpo.apply_central_impulse(dir_empuje * fuerza_empuje_pasivo * delta * 50)
					# --- NUEVO: SOPORTE PARA EMPUJAR ENEMIGOS ---
					elif cuerpo is CharacterBody3D and cuerpo.has_method("recibir_impacto"):
						# Usamos una fracción de la fuerza para solo apartarlos
						cuerpo.recibir_impacto(dir_empuje * (fuerza_empuje_pasivo * 0.5))
		# Si llega cerca del jugador, da el colazo
		if distancia_plana <= 4.0: 
			ejecutar_colazo()
			estado_actual = Estado.REGRESANDO
			return
			
	elif estado_actual == Estado.REGRESANDO:
		objetivo_pos = arbol.global_position
		var distancia_plana = Vector2(global_position.x, global_position.z).distance_to(Vector2(objetivo_pos.x, objetivo_pos.z))
		if distancia_plana <= 2.0: 
			llegar_a_madriguera()
			return

	var direccion = global_position.direction_to(objetivo_pos)
	direccion.y = 0 
	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad

	move_and_slide()

# --- FUNCIÓN NUEVA: EL COLAZO ---
func ejecutar_colazo() -> void:
	print("¡EL PRIMO DA UN COLAZO!")
	# Puedes añadir aquí una llamada a AnimationPlayer: $AnimationPlayer.play("Colazo")
	
	# Buscamos todo lo que esté en el radio de impacto
	var enemigos = get_tree().get_nodes_in_group("enemy")
	for enemigo in enemigos:
		var dist = global_position.distance_to(enemigo.global_position)
		if dist <= radio_colazo:
			var dir_vuelo = (enemigo.global_position - global_position).normalized()
			dir_vuelo.y = 0.6 # Ángulo hacia arriba para que "vuelen"
			
			# Si el enemigo es RigidBody3D
			if enemigo is RigidBody3D:
				enemigo.apply_central_impulse(dir_vuelo * fuerza_colazo)
			# CORRECCIÓN: Si es CharacterBody3D usamos el método correcto
			elif enemigo.has_method("recibir_impacto"):
				enemigo.recibir_impacto(dir_vuelo * fuerza_colazo)
				
				
func _on_timer_timeout() -> void:
	if not is_instance_valid(arbol): return
	var direccion_salida = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	global_position = arbol.global_position + (direccion_salida * 2.0)
	visual.visible = true
	estado_actual = Estado.YENDO_AL_JUGADOR

func llegar_a_madriguera() -> void:
	visual.visible = false
	estado_actual = Estado.ESCONDIDA
	timer_salida.start()

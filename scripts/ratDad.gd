extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visual_mesh = $body
@onready var area_mordida = $biteArea
@onready var area_colazo = $tailArea
@onready var area_contacto = $auraArea

# --- VARIABLES DE POWER UPS ---
# ---  (COLA) ---
var cola_afilada: bool = false
var cola_venenosa: bool = false
var cola_pesada: bool = false # Representa la "Piedra"

# --- VARIABLES DE GAME OVER ---
var arbol_central: Node3D
@export var limite_bosque: float = 25.0 # Distancia fatal. Ajusta este número según el tamaño de tu terreno

# --- VARIABLES DE ARRASTRE Y ATAQUES ---
var vector_arrastre: Vector3 = Vector3.ZERO
var cooldown_mordida: float = 0.0
var cooldown_colazo: float = 0.0
var tiempo_mordida: float = 12.0
var tiempo_colazo: float = 6.0


func _ready() -> void:
	# Buscamos el árbol de protección apenas nace la rata
	await get_tree().physics_frame
	arbol_central = get_tree().get_first_node_in_group("CentralTree")

func _physics_process(delta: float) -> void:
	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Mecánica de Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Obtener el vector de entrada (Input en 8 direcciones)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 4. Calcular velocidad de movimiento base por Input
	var target_velocity_x = 0.0
	var target_velocity_z = 0.0

	if direction:
		target_velocity_x = direction.x * SPEED
		target_velocity_z = direction.z * SPEED
		
		# --- ROTACIÓN INDEPENDIENTE DEL ARRASTRE ---
		# La rotación visual SOLO responde a la dirección del input
		var target_rotation = atan2(direction.x, direction.z)
		visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, target_rotation, 15 * delta)
	else:
		# Si el jugador no presiona nada, la velocidad de input tiende a cero
		target_velocity_x = move_toward(velocity.x - vector_arrastre.x, 0, SPEED)
		target_velocity_z = move_toward(velocity.z - vector_arrastre.z, 0, SPEED)

	# 5. --- LA MAGIA: SUMAR EL ARRASTRE AL INPUT ---
	# La velocidad final es lo que el jugador intenta moverse + la fuerza centrífuga que le aplican
	velocity.x = target_velocity_x + vector_arrastre.x
	velocity.z = target_velocity_z + vector_arrastre.z

	move_and_slide()

	# --- RUTINA DE ATAQUES AUTOMÁTICOS ---
	cooldown_mordida -= delta
	if cooldown_mordida <= 0:
		ejecutar_mordida()
		cooldown_mordida = tiempo_mordida

	cooldown_colazo -= delta
	if cooldown_colazo <= 0:
		ejecutar_colazo()
		cooldown_colazo = tiempo_colazo
		
# --- RUTINA DE ATAQUES AUTOMÁTICOS MEJORADA ---
	# (Pon esto dentro de tu _physics_process)
	
	if cooldown_mordida > 0:
		cooldown_mordida -= delta
	else:
		# Intenta morder. Si lo logra, entonces inicia el cooldown.
		if ejecutar_mordida():
			cooldown_mordida = tiempo_mordida

	if cooldown_colazo > 0:
		cooldown_colazo -= delta
	else:
		# Intenta dar el colazo. Si golpea a alguien, inicia el cooldown.
		if ejecutar_colazo():
			cooldown_colazo = tiempo_colazo
	# --- CONDICIÓN DE GAME OVER: EL BOSQUE PROFUNDO ---
	if arbol_central:
		var distancia_al_arbol = global_position.distance_to(arbol_central.global_position)
		if distancia_al_arbol > limite_bosque:
			activar_game_over()


# --- LÓGICA DE ATAQUES MODIFICADA ---
# Devuelven un 'bool' para avisar si impactaron a alguien
func ejecutar_mordida() -> bool:
	var mordio_algo = false
	
	for body in area_mordida.get_overlapping_bodies():
		if body == self:
			continue # Ignorarnos a nosotros mismos
			
		# Obtenemos todas las etiquetas (grupos) del objeto
		var grupos = body.get_groups()
		var es_objeto_especial = false
		
		# Evaluamos usando match (switch) sobre los nombres de los grupos
		for grupo in grupos:
			match String(grupo): # Forzamos a String por seguridad
				
				"CentralTree":
					if not cola_afilada:
						cola_afilada = true
						print("¡Obtuviste: Cola Afilada (Huesos/Madera)!")
					es_objeto_especial = true
					
				"serpiente":
					if not cola_venenosa:
						cola_venenosa = true
						print("¡Obtuviste: Cola Venenosa!")
					if body.has_method("desaparecer"):
						body.desaparecer()
					else:
						body.queue_free()
					es_objeto_especial = true
					
				"mineral":
					if not cola_pesada:
						cola_pesada = true
						print("¡Obtuviste: Cola Pesada (Piedra)!")
					if body.has_method("desaparecer"):
						body.desaparecer()
					else:
						body.queue_free()
					es_objeto_especial = true

		# 1. Si el match encontró un power up, validamos la mordida
		if es_objeto_especial:
			mordio_algo = true
			
		# 2. Si no fue un power up, pero es un enemigo normal
		elif body.has_method("desaparecer"):
			body.desaparecer()
			mordio_algo = true

		# Si logramos morder CUALQUIER cosa, nos liberamos y terminamos
		if mordio_algo:
			romper_arrastre()
			return true 
			
	return false # No mordimos nada

func ejecutar_colazo() -> bool:
	var acerto_golpe = false
	
	for body in area_colazo.get_overlapping_bodies():
		if body is CharacterBody3D and body != self:
			
			# Valores por defecto del ataque
			var fuerza_base = 15.0
			var aplicar_sangrado = false
			var aplicar_veneno = false
			
			# Evaluamos todas las combinaciones posibles usando un arreglo: [Afilada, Venenosa, Pesada]
			match [cola_afilada, cola_venenosa, cola_pesada]:
				
				[false, false, false]: 
					pass # Cola normal, usamos los valores por defecto
					
				[true, false, false]: # SOLO AFILADA
					aplicar_sangrado = true
					
				[false, true, false]: # SOLO VENENOSA
					aplicar_veneno = true
					
				[false, false, true]: # SOLO PESADA
					fuerza_base = 30.0 # Doble de empuje
					
				[true, true, false]: # AFILADA + VENENOSA
					aplicar_sangrado = true
					aplicar_veneno = true
					# Aquí podrías poner lógica extra exclusiva de esta combinación
					
				[true, false, true]: # AFILADA + PESADA
					fuerza_base = 30.0
					aplicar_sangrado = true
					
				[false, true, true]: # VENENOSA + PESADA
					fuerza_base = 30.0
					aplicar_veneno = true
					
				[true, true, true]: # ¡LAS TRES JUNTAS!
					fuerza_base = 40.0 # Un bonus extra por tener las tres
					aplicar_sangrado = true
					aplicar_veneno = true

			# --- APLICAMOS LOS EFECTOS AL ENEMIGO ---
			if aplicar_sangrado and body.has_method("aplicar_sangrado"):
				body.aplicar_sangrado()
				
			if aplicar_veneno and body.has_method("aplicar_veneno"):
				body.aplicar_veneno()
				
			if body.has_method("recibir_impacto"):
				var empuje = (body.global_position - global_position).normalized() * fuerza_base
				body.recibir_impacto(empuje)
				acerto_golpe = true
				
	if acerto_golpe:
		romper_arrastre()
		
	return acerto_golpe

# --- MÉTODOS DE CONTROL DE ARRASTRE ---
func aplicar_arrastre(fuerza: Vector3):
	vector_arrastre = fuerza

func romper_arrastre():
	vector_arrastre = Vector3.ZERO

func activar_game_over() -> void:
	print("¡El bosque profundo te ha consumido!")
	# Opción A: Reiniciar la partida inmediatamente (Estilo Roguelike rápido)
	get_tree().reload_current_scene()
	# Opción B: Mandarlo al menú principal (Descomenta la línea de abajo si lo prefieres)
	#get_tree().change_scene_to_file("res://entities/mainMenu.tscn")

func _on_aura_area_body_entered(body: Node3D) -> void:
	# Dejamos esto vacío con "pass" para no alterar la velocidad enemiga
	# Opcionalmente, puedes eliminar esta función y desconectar la señal si no la usarás para nada más
	pass


func _on_aura_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		romper_arrastre() # <--- NUEVO: Si el enemigo se aleja, nos suelta

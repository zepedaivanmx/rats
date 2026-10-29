extends CharacterBody3D

@export var velocidad_base: float = 5.0
var speed: float = 7.0
var objeto_cargado: Node3D = null
signal inventario_cambiado(cantidad: int)

@export var capacidad_inventario: int = 5   # PROVISIONAL
var inventario: Array[Recolectable] = []

const JUMP_VELOCITY = 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visual_mesh = $body
@onready var area_mordida = $biteArea
@onready var area_colazo = $tailArea
@onready var area_contacto = $auraArea
@onready var area_recogida = $pickupArea

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
var tiempo_mordida: float = 2.0
var tiempo_colazo: float = 5.0

 


func _ready() -> void:
	# Buscamos el árbol de protección apenas nace la rata
	await get_tree().physics_frame
	arbol_central = get_tree().get_first_node_in_group("CentralTree")

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("recoger"):
		intentar_recoger()
	if Input.is_action_just_pressed("soltar"):
		soltar_objeto()
	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	if tiempo_aturdido > 0.0:
		tiempo_aturdido -= delta
		velocity.x = vector_arrastre.x
		velocity.z = vector_arrastre.z
		move_and_slide()
		return

	# 2. Mecánica de Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Obtener el vector de entrada (Input en 8 direcciones)
	var input_dir := Input.get_vector("ui_right", "ui_left", "ui_up", "ui_down")
	var direction := Vector3.ZERO
	
	if arbol_central:
		# Calculamos el vector que apunta desde el árbol hacia la rata (eje radial)
		var radial_dir = (global_position - arbol_central.global_position)
		radial_dir.y = 0 # Ignoramos la altura para no volar
		
		# Si la rata está exactamente en el centro, evitamos errores matemáticos
		if radial_dir.length() < 0.1:
			radial_dir = Vector3.FORWARD
		else:
			radial_dir = radial_dir.normalized()
			
		# Calculamos el vector perpendicular (eje tangencial, para orbitar)
		var tangent_dir = Vector3.UP.cross(radial_dir).normalized()
		
		# Sumamos las direcciones basadas en lo que presiona el jugador
		# -input_dir.y (arriba/abajo): el negativo aleja del árbol, el positivo acerca
		# input_dir.x (izq/der): mueve en el círculo orbital
		direction = (tangent_dir * input_dir.x) + (radial_dir * -input_dir.y)
		direction = direction.normalized()
	else:
		# Fallback de seguridad si el árbol no existe
		direction = (Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 4. Calcular velocidad de movimiento base por Input
	var target_velocity_x = 0.0
	var target_velocity_z = 0.0

	if direction:
		target_velocity_x = direction.x * speed
		target_velocity_z = direction.z * speed
		
		# --- ROTACIÓN INDEPENDIENTE DEL ARRASTRE ---
		# La rotación visual SOLO responde a la dirección del input
		var target_rotation = atan2(direction.x, direction.z)
		visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, target_rotation, 15 * delta)
	else:
		# Si el jugador no presiona nada, la velocidad de input tiende a cero
		target_velocity_x = move_toward(velocity.x - vector_arrastre.x, 0, speed)
		target_velocity_z = move_toward(velocity.z - vector_arrastre.z, 0, speed)

	# 5. --- LA MAGIA: SUMAR EL ARRASTRE AL INPUT ---
	# La velocidad final es lo que el jugador intenta moverse + la fuerza centrífuga que le aplican
	velocity.x = target_velocity_x + vector_arrastre.x
	velocity.z = target_velocity_z + vector_arrastre.z

	move_and_slide()

	# --- RUTINA DE ATAQUES AUTOMÁTICOS ÚNICA Y CORREGIDA ---
	if cooldown_mordida > 0:
		cooldown_mordida -= delta
	else:
		# Intenta morder. Si lo logra (devuelve true), inicia el cooldown
		if ejecutar_mordida():
			cooldown_mordida = tiempo_mordida

	if cooldown_colazo > 0:
		cooldown_colazo -= delta
	else:
		# Intenta dar el colazo. Si golpea a alguien, inicia el cooldown
		if ejecutar_colazo():
			cooldown_colazo = tiempo_colazo
			
	# --- CONDICIÓN DE GAME OVER: EL BOSQUE PROFUNDO ---
	if arbol_central:
		var distancia_al_arbol = global_position.distance_to(arbol_central.global_position)
		if distancia_al_arbol > limite_bosque:
			activar_game_over()


# --- LÓGICA DE ATAQUES MODIFICADA ---
# Devuelven un 'bool' para avisar si impactaron a alguien
var tiempo_aturdido: float = 0.0

func aplicar_aturdimiento(duracion: float) -> void:
	tiempo_aturdido = max(tiempo_aturdido, duracion)
	print("¡La rata ha sido aturdida por ", duracion, " segundos!")

func ejecutar_mordida() -> bool:
	if is_instance_valid(objeto_cargado) or tiempo_aturdido > 0.0:
		return false # Si lleva algo en la boca o está aturdida, no muerde
	
	var mordio_algo = false
	for body in area_mordida.get_overlapping_bodies():
		if body == self:
			continue
		if body is Recolectable and not (body is PrimordialFather):
			continue
		if body is PrimordialFather and body.esta_muerto:
			continue
		
		# Morder ya NO otorga power-ups; solo hace daño leve cuerpo a cuerpo
		if body.is_in_group("enemy") and body.has_method("recibir_dano"):
			body.recibir_dano(20.0)
			mordio_algo = true
			
	if mordio_algo:
		romper_arrastre()
		return true
	return false

func entregar_objeto() -> Node3D:
	if not is_instance_valid(objeto_cargado):
		return null
	var obj = objeto_cargado
	objeto_cargado = null
	speed = velocidad_base
	return obj

func ejecutar_colazo() -> bool:
	if tiempo_aturdido > 0.0:
		return false
	var acerto_golpe = false
	for body in area_colazo.get_overlapping_bodies():
		if body is CharacterBody3D and body != self and body.is_in_group("enemy"):
			if body.get("esta_muerto") == true:
				continue
			var fuerza_base = 15.0
			var dano_colazo = 35.0 # Suficiente para matar a la Hormiga base (35 HP) de 1 golpe de cola
			var aplicar_sangrado = cola_afilada
			var aplicar_veneno = cola_venenosa
			
			if cola_pesada:
				fuerza_base = 30.0
				if cola_afilada and cola_venenosa:
					fuerza_base = 40.0
			
			if aplicar_sangrado and body.has_method("aplicar_sangrado"):
				body.aplicar_sangrado()
			if aplicar_veneno and body.has_method("aplicar_veneno"):
				body.aplicar_veneno()
			if body.has_method("recibir_impacto"):
				var empuje = (body.global_position - global_position).normalized() * fuerza_base
				body.recibir_impacto(empuje)
			if body.has_method("recibir_dano"):
				body.recibir_dano(dano_colazo)
			
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

func soltar_objeto() -> Node3D:
	if not is_instance_valid(objeto_cargado): return null
		
	var obj = objeto_cargado
	objeto_cargado = null
	speed = velocidad_base # Recupera su velocidad normal
	
	if obj.has_method("ser_soltado"):
		obj.ser_soltado(global_position)
		
	return obj

func intentar_recoger() -> void:
	# 1. PRIORIDAD: Dar orden al aliado si está dentro del área (pickupArea)
	for body in area_recogida.get_overlapping_bodies():
		if body.is_in_group("aliados") and body.has_method("alternar_orden_patrulla"):
			body.alternar_orden_patrulla()
			# Salimos de la función inmediatamente para no recoger un objeto accidentalmente
			return 

	# 2. SECUNDARIO: Recoger objetos (Tu lógica original intacta)
	if is_instance_valid(objeto_cargado):
		return   # ya lleva algo en la boca
		
	var mejor: Recolectable = null
	var mejor_dist := INF
	
	for body in area_recogida.get_overlapping_bodies():
		if body is Recolectable and body.puede_ser_recogido():
			if body.modo_recogida == Recolectable.ModoRecogida.INVENTARIO \
			and inventario.size() >= capacidad_inventario:
				continue   # inventario lleno
				
			var d := global_position.distance_squared_to(body.global_position)
			if d < mejor_dist:
				mejor_dist = d
				mejor = body
				
	if not mejor:
		return
		
	mejor.ser_recogido(self)
	
	if mejor.modo_recogida == Recolectable.ModoRecogida.INVENTARIO:
		inventario.append(mejor)
		inventario_cambiado.emit(inventario.size())
	else:
		objeto_cargado = mejor
		speed = velocidad_base * (0.5 if mejor.get("es_pesado") == true else 1.0)

func vaciar_inventario() -> Array[Recolectable]:
	var items: Array[Recolectable] = inventario.duplicate()
	inventario.clear()
	inventario_cambiado.emit(0)
	return items

func _on_aura_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		romper_arrastre() # <--- NUEVO: Si el enemigo se aleja, nos suelta

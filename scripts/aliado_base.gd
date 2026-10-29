class_name AliadoBase
extends CharacterBody3D

enum EstadoAliado {
	DESACTIVADO,
	CAMINANDO_A_ZONA,
	GUARDANDO_POSICION,
	SIGUIENDO_JUGADOR,
	ATACANDO,
	REGRESANDO_A_GUARDIA
}

var estado_actual: EstadoAliado = EstadoAliado.DESACTIVADO
var orden_actual: EstadoAliado = EstadoAliado.GUARDANDO_POSICION

@export var hp_maximo: float = 50.0
@export var velocidad: float = 4.0
@export var rango_ataque: float = 1.8
@export var intervalo_ataque: float = 1.5
@export var interactuable_por_rata: bool = true
@export var es_estatico: bool = false

var hp: float
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var posicion_guardia: Vector3 = Vector3.ZERO
var jugador: Node3D
var enemigo_objetivo: Node3D = null
var cooldown_ataque: float = 0.0

@onready var nav_agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")
@onready var area_ataque: Area3D = get_node_or_null("AreaAtaque")

func _ready() -> void:
	# Independizamos su transformación global para que escalar la zona no deforme al animal
	top_level = true
	add_to_group("aliados")
	hp = hp_maximo
	jugador = get_tree().get_first_node_in_group("rats")
	
	if area_ataque:
		area_ataque.body_entered.connect(_on_enemigo_detectado)
		area_ataque.body_exited.connect(_on_enemigo_perdido)
	
	_inicializar_aliado()
	
	# Inicia invisible y deshabilitado hasta que su zona procese un cadáver
	desactivar_aliado()


func _physics_process(delta: float) -> void:
	if estado_actual == EstadoAliado.DESACTIVADO:
		return
	
	# 1. Gravedad (solo para aliados móviles; las torretas en raíces altas mantienen su altura)
	if es_estatico:
		velocity = Vector3.ZERO
	elif not is_on_floor():
		velocity.y -= gravedad * delta
	
	if cooldown_ataque > 0.0:
		cooldown_ataque -= delta
	
	# 2. Máquina de Estados Central
	match estado_actual:
		EstadoAliado.CAMINANDO_A_ZONA, EstadoAliado.REGRESANDO_A_GUARDIA:
			_procesar_regreso_a_guardia(delta)
		EstadoAliado.GUARDANDO_POSICION:
			_procesar_guardia(delta)
		EstadoAliado.SIGUIENDO_JUGADOR:
			_procesar_seguimiento(delta)
		EstadoAliado.ATACANDO:
			_procesar_ataque(delta)
	
	# 3. Rotación visual fluida hacia donde camina
	var vel_plana := Vector2(velocity.x, velocity.z)
	if vel_plana.length_squared() > 0.05:
		var target_rotation := atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 12.0 * delta)
	
	# 4. Aplicar movimiento físico
	if not es_estatico:
		move_and_slide()

# ==========================================
# ACTIVACIÓN Y ESTADOS DE MOVIMIENTO
# ==========================================

func desactivar_aliado() -> void:
	estado_actual = EstadoAliado.DESACTIVADO
	visible = false
	collision_layer = 0
	collision_mask = 0
	if area_ataque:
		area_ataque.monitoring = false

func activar_desde_bosque_profundo(pos_aparicion: Vector3, pos_destino_zona: Vector3) -> void:
	global_position = pos_aparicion
	posicion_guardia = pos_destino_zona
	visible = true
	collision_layer = 1
	collision_mask = 1
	if area_ataque:
		area_ataque.monitoring = true
	
	orden_actual = EstadoAliado.GUARDANDO_POSICION
	caminar_hacia(pos_destino_zona)

func _procesar_regreso_a_guardia(_delta: float) -> void:
	var mi_pos_2d := Vector2(global_position.x, global_position.z)
	var destino_2d := Vector2(posicion_guardia.x, posicion_guardia.z)
	var dist_plana := mi_pos_2d.distance_to(destino_2d)
	
	# Verificamos llegada real por distancia plana para no detenernos antes de tiempo
	if dist_plana <= 1.2:
		_al_llegar_a_destino()
		return
	
	var siguiente_pos := posicion_guardia
	if nav_agent:
		nav_agent.target_position = posicion_guardia
		var nav_next := nav_agent.get_next_path_position()
		if Vector2(nav_next.x, nav_next.z).distance_to(mi_pos_2d) > 0.15:
			siguiente_pos = nav_next
	
	_mover_hacia_objetivo(siguiente_pos)

func _procesar_guardia(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, velocidad)
	velocity.z = move_toward(velocity.z, 0.0, velocidad)
	_buscar_enemigos_en_area()

func _procesar_seguimiento(_delta: float) -> void:
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("rats")
		if not is_instance_valid(jugador):
			estado_actual = EstadoAliado.GUARDANDO_POSICION
			return
	
	if nav_agent:
		nav_agent.target_position = jugador.global_position
	
	if global_position.distance_to(jugador.global_position) < 2.2:
		velocity.x = move_toward(velocity.x, 0.0, velocidad)
		velocity.z = move_toward(velocity.z, 0.0, velocidad)
	else:
		var siguiente_pos := nav_agent.get_next_path_position() if nav_agent else jugador.global_position
		_mover_hacia_objetivo(siguiente_pos)
	
	_buscar_enemigos_en_area()

func _mover_hacia_objetivo(siguiente_pos: Vector3) -> void:
	if es_estatico:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var direccion := global_position.direction_to(siguiente_pos)
	direccion.y = 0.0
	if direccion.length_squared() > 0.001:
		direccion = direccion.normalized()
	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad

# ==========================================
# DETECCIÓN SENSORIAL Y COMBATE
# ==========================================

func _es_enemigo_valido(body: Node3D) -> bool:
	return is_instance_valid(body) and body.is_in_group("enemy") and body.get("esta_muerto") != true

func _on_enemigo_detectado(body: Node3D) -> void:
	if estado_actual == EstadoAliado.DESACTIVADO or estado_actual == EstadoAliado.CAMINANDO_A_ZONA:
		return
	if _es_enemigo_valido(body) and estado_actual != EstadoAliado.ATACANDO:
		enemigo_objetivo = body
		estado_actual = EstadoAliado.ATACANDO

func _on_enemigo_perdido(body: Node3D) -> void:
	if body == enemigo_objetivo:
		_finalizar_ataque_actual()

func _buscar_enemigos_en_area() -> void:
	if not area_ataque or not area_ataque.monitoring:
		return
	for body in area_ataque.get_overlapping_bodies():
		if _es_enemigo_valido(body):
			enemigo_objetivo = body
			estado_actual = EstadoAliado.ATACANDO
			return

func _procesar_ataque(_delta: float) -> void:
	if not _es_enemigo_valido(enemigo_objetivo):
		_finalizar_ataque_actual()
		return
	
	var dist := Vector2(global_position.x, global_position.z).distance_to(
		Vector2(enemigo_objetivo.global_position.x, enemigo_objetivo.global_position.z)
	)
	
	if not es_estatico and dist > rango_ataque:
		_mover_hacia_objetivo(enemigo_objetivo.global_position)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	if cooldown_ataque <= 0.0 and (es_estatico or dist <= rango_ataque + 0.4):
		_ejecutar_ataque_especifico(enemigo_objetivo)
		cooldown_ataque = intervalo_ataque
		if not _es_enemigo_valido(enemigo_objetivo):
			_finalizar_ataque_actual()

func _finalizar_ataque_actual() -> void:
	enemigo_objetivo = null
	# Si hay otro enemigo dentro del área, sigue atacando
	if area_ataque and area_ataque.monitoring:
		for body in area_ataque.get_overlapping_bodies():
			if _es_enemigo_valido(body):
				enemigo_objetivo = body
				estado_actual = EstadoAliado.ATACANDO
				return
	
	# Si su orden era seguir al jugador, retoma el seguimiento; si era cuidar zona, regresa al punto donde fue dejado
	if orden_actual == EstadoAliado.SIGUIENDO_JUGADOR:
		estado_actual = EstadoAliado.SIGUIENDO_JUGADOR
	else:
		if nav_agent:
			nav_agent.target_position = posicion_guardia
		estado_actual = EstadoAliado.REGRESANDO_A_GUARDIA

# ==========================================
# COMANDOS PÚBLICOS (Interacción con la Rata)
# ==========================================

func caminar_hacia(posicion: Vector3) -> void:
	posicion_guardia = posicion
	if nav_agent:
		nav_agent.target_position = posicion_guardia
	estado_actual = EstadoAliado.CAMINANDO_A_ZONA

func seguir_al_jugador() -> void:
	orden_actual = EstadoAliado.SIGUIENDO_JUGADOR
	estado_actual = EstadoAliado.SIGUIENDO_JUGADOR

func alternar_orden_patrulla() -> void:
	if not interactuable_por_rata or estado_actual == EstadoAliado.DESACTIVADO:
		return
	
	if orden_actual == EstadoAliado.SIGUIENDO_JUGADOR:
		# Se queda exactamente donde está y cuida esa zona
		posicion_guardia = global_position
		orden_actual = EstadoAliado.GUARDANDO_POSICION
		if estado_actual != EstadoAliado.ATACANDO:
			estado_actual = EstadoAliado.GUARDANDO_POSICION
			velocity.x = 0.0
			velocity.z = 0.0
		print(name, ": Orden recibida -> Cuidando esta posición: ", posicion_guardia)
	else:
		enemigo_objetivo = null
		seguir_al_jugador()
		print(name, ": Orden recibida -> Siguiendo a la rata.")

# ==========================================
# DAÑO Y HOOKS VIRTUALES
# ==========================================

func recibir_dano(cantidad: float) -> void:
	hp -= cantidad
	if hp <= 0.0:
		queue_free()

func _inicializar_aliado() -> void:
	pass

func _al_llegar_a_destino() -> void:
	estado_actual = EstadoAliado.GUARDANDO_POSICION
	velocity.x = 0.0
	velocity.z = 0.0

func _ejecutar_ataque_especifico(_objetivo: Node3D) -> void:
	pass

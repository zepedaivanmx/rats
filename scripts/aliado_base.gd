class_name AliadoBase extends CharacterBody3D

enum EstadoAliado { SPAWNEANDO, IDLE, MOVIENDOSE, SIGUIENDO_JUGADOR, YENDO_A_PATRULLAR, PATRULLANDO_MADRIGUERA, ATACANDO }
var estado_actual: EstadoAliado = EstadoAliado.SPAWNEANDO

@export var hp_maximo: float = 50.0
@export var velocidad: float = 4.0
var hp: float
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var destino_movimiento: Vector3
var jugador: Node3D 

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	add_to_group("aliados")
	hp = hp_maximo
	jugador = get_tree().get_first_node_in_group("rats")
	_inicializar_aliado()

func _physics_process(delta: float) -> void:
	# 1. Gravedad
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# 2. Máquina de Estados Central
	match estado_actual:
		EstadoAliado.MOVIENDOSE, EstadoAliado.YENDO_A_PATRULLAR:
			_procesar_movimiento(delta)
		EstadoAliado.SIGUIENDO_JUGADOR:
			_procesar_seguimiento(delta)
		EstadoAliado.PATRULLANDO_MADRIGUERA:
			_procesar_patrullaje_circular(delta)
		EstadoAliado.IDLE:
			_procesar_idle(delta)
		EstadoAliado.ATACANDO:
			_procesar_ataque(delta)

	# 3. Rotación visual fluida hacia donde se mueve
	if velocity.length_squared() > 0.1:
		var target_rotation = atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 12.0 * delta)

	# 4. Aplicar el movimiento al motor de físicas
	move_and_slide()


# ==========================================
# LÓGICA INTERNA DE NAVEGACIÓN Y ESTADOS
# ==========================================

func _procesar_movimiento(_delta: float) -> void:
	# Si llegamos al destino final o el navegador falló
	if not nav_agent or nav_agent.is_navigation_finished():
		if estado_actual == EstadoAliado.YENDO_A_PATRULLAR:
			# Si la orden era patrullar, al llegar iniciamos la órbita
			estado_actual = EstadoAliado.PATRULLANDO_MADRIGUERA
		else:
			# Comportamiento polimórfico (Hook) para cuando los aliados llegan de la arena/pasto
			_al_llegar_a_destino()
		return
		
	# Si aún no llegamos, avanzamos por el NavMesh
	_mover_hacia_objetivo(nav_agent.get_next_path_position())

func _procesar_seguimiento(_delta: float) -> void:
	# Verificación de seguridad por si el jugador (la rata) muere o es eliminada
	if not is_instance_valid(jugador) or not nav_agent:
		estado_actual = EstadoAliado.IDLE
		return

	# El objetivo se actualiza constantemente hacia la rata
	nav_agent.target_position = jugador.global_position
	
	# Frenado suave: evita empujar físicamente a la rata al alcanzarla
	if global_position.distance_to(jugador.global_position) < 2.0:
		velocity.x = move_toward(velocity.x, 0, velocidad)
		velocity.z = move_toward(velocity.z, 0, velocidad)
		return
		
	_mover_hacia_objetivo(nav_agent.get_next_path_position())

func _procesar_patrullaje_circular(_delta: float) -> void:
	var arbol = get_tree().get_first_node_in_group("CentralTree")
	if not is_instance_valid(arbol):
		estado_actual = EstadoAliado.IDLE
		return
		
	var centro = arbol.global_position
	var mi_pos = global_position
	centro.y = mi_pos.y # Mantenemos el plano 2D (Y constante) para cálculos
	
	var distancia = mi_pos.distance_to(centro)
	var radio_ideal = 5.0 # Distancia de la órbita defensiva
	
	if distancia < 0.1:
		mi_pos.x += 0.1 
		distancia = 0.1
		
	var dir_hacia_arbol = mi_pos.direction_to(centro)
	var dir_tangente = Vector3.UP.cross(dir_hacia_arbol).normalized()
	
	var factor_acercamiento = (distancia - radio_ideal) * 1.5
	var direccion_final = (dir_tangente + (dir_hacia_arbol * factor_acercamiento)).normalized()
	
	velocity.x = direccion_final.x * velocidad
	velocity.z = direccion_final.z * velocidad

func _mover_hacia_objetivo(siguiente_pos: Vector3) -> void:
	var direccion = global_position.direction_to(siguiente_pos)
	direccion.y = 0 # Ignorar la altura para que el aliado no vuele
	
	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad


# ==========================================
# COMANDOS PÚBLICOS (API para el Jugador y las Zonas)
# ==========================================

func caminar_hacia(posicion: Vector3) -> void:
	destino_movimiento = posicion
	if nav_agent:
		nav_agent.target_position = destino_movimiento
	estado_actual = EstadoAliado.MOVIENDOSE

func seguir_al_jugador() -> void:
	estado_actual = EstadoAliado.SIGUIENDO_JUGADOR

func alternar_orden_patrulla() -> void:
	# Botón E contextual: Si estaba siguiendo, va al árbol. Si no, sigue.
	if estado_actual == EstadoAliado.SIGUIENDO_JUGADOR:
		var arbol = get_tree().get_first_node_in_group("CentralTree")
		if arbol:
			caminar_hacia(arbol.global_position)
			estado_actual = EstadoAliado.YENDO_A_PATRULLAR 
			print(name, ": Orden recibida -> Yendo a la madriguera a patrullar.")
	else:
		seguir_al_jugador()
		print(name, ": Orden recibida -> Siguiendo a la rata.")


# ==========================================
# SISTEMA DE DAÑO Y MUERTE
# ==========================================

func recibir_dano(cantidad: float) -> void:
	hp -= cantidad
	if hp <= 0:
		_morir()

func _morir() -> void:
	# Aquí podrías instanciar un cadáver si quieres que los aliados también dejen recursos
	queue_free()


# ==========================================
# MÉTODOS VIRTUALES (Hooks para Polimorfismo en Lagarto/Escarabajo)
# ==========================================

func _inicializar_aliado() -> void:
	pass

func _al_llegar_a_destino() -> void:
	estado_actual = EstadoAliado.IDLE
	velocity.x = 0
	velocity.z = 0

func _procesar_idle(_delta: float) -> void:
	pass

func _procesar_ataque(_delta: float) -> void:
	pass

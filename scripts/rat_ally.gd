extends CharacterBody3D

# --- ESTADOS DE LA RATA ---
enum Estado { ESCONDIDA, YENDO_AL_JUGADOR, REGRESANDO }
var estado_actual = Estado.ESCONDIDA

@export var velocidad: float = 8.0
@export var piedra_scene: PackedScene # Arrastra aquí tu piedra.tscn

var arbol: Node3D
var jugador: Node3D
var timer_salida: Timer

@onready var visual = $MeshInstance3D # Asegúrate de que el nombre coincida con tu nodo visual
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	visual.visible = false
	
	# Buscar referencias clave usando los grupos de tu proyecto
	await get_tree().physics_frame
	arbol = get_tree().get_first_node_in_group("CentralTree")
	jugador = get_tree().get_first_node_in_group("rats")
	
	# Crear el temporizador por código para mantenerlo limpio
	timer_salida = Timer.new()
	timer_salida.wait_time = 10.0
	timer_salida.one_shot = true
	timer_salida.timeout.connect(_on_timer_timeout)
	add_child(timer_salida)
	timer_salida.start()

func _physics_process(delta: float) -> void:
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# Si está escondida, no se mueve
	if estado_actual == Estado.ESCONDIDA:
		return

	if not is_instance_valid(jugador) or not is_instance_valid(arbol):
		return

	var objetivo_pos = Vector3.ZERO

	# Lógica de Máquina de Estados
	if estado_actual == Estado.YENDO_AL_JUGADOR:
		objetivo_pos = jugador.global_position
		
		# MEDIR DISTANCIA PLANA (Ignorando la altura Y)
		var mi_pos_2d = Vector2(global_position.x, global_position.z)
		var obj_pos_2d = Vector2(objetivo_pos.x, objetivo_pos.z)
		var distancia_plana = mi_pos_2d.distance_to(obj_pos_2d)
		
		# Si llega a ~2.5 metros horizontales del jugador
		if distancia_plana <= 7: 
			disparar()
			estado_actual = Estado.REGRESANDO
			return
			
	elif estado_actual == Estado.REGRESANDO:
		objetivo_pos = arbol.global_position
		
		# MEDIR DISTANCIA PLANA (Ignorando la altura Y)
		var mi_pos_2d = Vector2(global_position.x, global_position.z)
		var obj_pos_2d = Vector2(objetivo_pos.x, objetivo_pos.z)
		var distancia_plana = mi_pos_2d.distance_to(obj_pos_2d)
		
		# Si llega a ~1.5 metros horizontales del árbol
		if distancia_plana <= 1.5: 
			llegar_a_madriguera()
			return

	# Movimiento hacia el objetivo
	var direccion = global_position.direction_to(objetivo_pos)
	direccion.y = 0 # Ignorar la altura para no volar
	
	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad

	move_and_slide()

func _on_timer_timeout() -> void:
	if not is_instance_valid(arbol): return
	
	# Aparecer a ~1.5 metros del árbol en una dirección aleatoria
	var direccion_salida = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	global_position = arbol.global_position + (direccion_salida * 1.5)
	
	visual.visible = true
	estado_actual = Estado.YENDO_AL_JUGADOR

func disparar() -> void:
	# Buscar a quién dispararle
	var enemigos = get_tree().get_nodes_in_group("enemy")
	var enemigo_cercano = null
	var distancia_minima = INF
	
	# Usar distancia plana también para buscar al enemigo
	var mi_pos_2d = Vector2(global_position.x, global_position.z)
	
	for enemigo in enemigos:
		var enemigo_pos_2d = Vector2(enemigo.global_position.x, enemigo.global_position.z)
		var distancia = mi_pos_2d.distance_to(enemigo_pos_2d)
		if distancia < distancia_minima:
			distancia_minima = distancia
			enemigo_cercano = enemigo

	# Instanciar y lanzar el proyectil físico SI hay un enemigo y SI hay piedra
	if enemigo_cercano and piedra_scene:
		var piedra = piedra_scene.instantiate()
		
		# Añadirlo al nodo padre general para que su física sea independiente
		get_parent().add_child(piedra)
		
		# Elevar la piedra un poco al instanciarla para que no choque con el suelo
		piedra.global_position = global_position + Vector3(0, 0.8, 0)
		
		# -- CALCULAR EL LANZAMIENTO PARABÓLICO --
		var direccion = piedra.global_position.direction_to(enemigo_cercano.global_position)
		var distancia_al_objetivo = piedra.global_position.distance_to(enemigo_cercano.global_position)
		
		var fuerza_horizontal = direccion * (distancia_al_objetivo * 2.0)
		var fuerza_vertical = Vector3(0, distancia_al_objetivo * 1.5, 0) 
		var impulso_final = fuerza_horizontal + fuerza_vertical
		
		piedra.apply_central_impulse(impulso_final)
	else:
		# Si no hay enemigos cerca, imprimimos en consola pero dejamos que la rata regrese
		print("La rata aliada salió pero no encontró enemigos cerca.")

func llegar_a_madriguera() -> void:
	visual.visible = false
	estado_actual = Estado.ESCONDIDA
	timer_salida.start() # Iniciar el ciclo de nuevo

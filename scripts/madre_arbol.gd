extends Node3D

# --- NUEVA SECCIÓN: SEÑALES ---
signal ciclo_cambiado(es_de_dia: bool)

# --- VARIABLES DEL CICLO DÍA/NOCHE ---
@export var sol_direccional: DirectionalLight3D
@export var duracion_fase: float = 150.0 # 150 segundos = 2 minutos y 30 segundos
var es_de_dia: bool = true

# Nuestra nueva variable para el nodo Timer
var timer_ciclo: Timer 

# --- VARIABLES DE CRECIMIENTO ---
var biomasa_acumulada: int = 0
@export var factor_crecimiento: float = 0.05


func _ready() -> void:
	if not is_in_group("CentralTree"):
		add_to_group("CentralTree")
	
	# 1. CREAMOS EL TIMER POR CÓDIGO (POO puro y encapsulado)
	timer_ciclo = Timer.new()
	timer_ciclo.name = "TimerDiaNoche"
	timer_ciclo.wait_time = duracion_fase
	timer_ciclo.one_shot = false
	timer_ciclo.autostart = true
	timer_ciclo.timeout.connect(cambiar_fase_dia_noche)
	add_child(timer_ciclo)
	
# 2. CONFIGURAMOS EL ÁREA DE LA MADRIGUERA PARA RECIBIR MINERAL Y HONGO
	var area_madriguera := get_node_or_null("../Area3D") as Area3D
	if area_madriguera:
		area_madriguera.collision_mask |= 1 | Recolectable.CAPA_RECOLECTABLE
		var col_shape := area_madriguera.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if col_shape and col_shape.shape is BoxShape3D:
			(col_shape.shape as BoxShape3D).size.y = 3.0
			col_shape.position.y = 1.0
		if not area_madriguera.body_entered.is_connected(_on_cuerpo_entro_madriguera):
			area_madriguera.body_entered.connect(_on_cuerpo_entro_madriguera)

func _process(_delta: float) -> void:
	# El process AHORA SOLO SE USA PARA LO VISUAL, la lógica pesada la lleva el Timer
	if sol_direccional and timer_ciclo:
		var tiempo_total_ciclo = duracion_fase * 2.0
		
		# El Timer nos dice cuánto falta (time_left va de 150 a 0). 
		# Lo invertimos para saber cuánto ha pasado (de 0 a 150).
		var tiempo_transcurrido = duracion_fase - timer_ciclo.time_left
		
		# Si es de noche, le sumamos el "día" para que el sol siga rotando por debajo del mundo
		var tiempo_absoluto = tiempo_transcurrido if es_de_dia else tiempo_transcurrido + duracion_fase
		
		# Calculamos y aplicamos la rotación (TAU = 360 grados en radianes)
		var angulo_rotacion = (-PI / 2.0) + (tiempo_absoluto / tiempo_total_ciclo) * TAU
		sol_direccional.rotation.x = angulo_rotacion

# --- FUNCIONES DEDICADAS ---
func cambiar_fase_dia_noche() -> void:
	es_de_dia = not es_de_dia
	
	var nombre_fase = "DÍA" if es_de_dia else "NOCHE"
	print("El Timer ha sonado. El bosque cambia... Ahora es de ", nombre_fase)
	
	# NUEVO: Avisamos a todos los nodos conectados que el ciclo cambió
	ciclo_cambiado.emit(es_de_dia) 
	
	procesar_crecimiento()

func absorber_cadaver() -> void:
	biomasa_acumulada += 1

func procesar_crecimiento() -> void:
	if biomasa_acumulada > 0:
		var crecimiento_total = biomasa_acumulada * factor_crecimiento
		scale += Vector3(crecimiento_total, crecimiento_total, crecimiento_total)
		print("¡El árbol ha crecido! Biomasa consumida: ", biomasa_acumulada)
		biomasa_acumulada = 0
		


func _on_cuerpo_entro_madriguera(body: Node3D) -> void:
	if body.is_in_group("rats"):
		var obj = body.get("objeto_cargado")
		if is_instance_valid(obj) and _es_recurso_mejora(obj):
			var entregado = body.soltar_objeto()
			if is_instance_valid(entregado):
				_aplicar_mejora_a_rata(body, entregado)
	elif _es_recurso_mejora(body):
		var rata := get_tree().get_first_node_in_group("rats")
		if is_instance_valid(rata):
			_aplicar_mejora_a_rata(rata, body)

func _es_recurso_mejora(obj: Node3D) -> bool:
	return is_instance_valid(obj) and (obj.is_in_group("mineral") or obj.is_in_group("hongo"))

func _aplicar_mejora_a_rata(rata: Node3D, recurso: Node3D) -> void:
	if recurso.is_in_group("mineral"):
		rata.set("cola_pesada", true)
		print("¡Madriguera consumió Mineral -> Obtuviste: Cola Pesada (Mucho Knockback)!")
		recurso.queue_free()
	elif recurso.is_in_group("hongo"):
		rata.set("cola_venenosa", true)
		print("¡Madriguera consumió Hongo -> Obtuviste: Cola Venenosa (Daño en el tiempo)!")
		recurso.queue_free()

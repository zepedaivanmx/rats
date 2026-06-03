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
	timer_ciclo.one_shot = false # Queremos que se repita en bucle
	timer_ciclo.autostart = true
	
	# 2. Conectamos la señal del Timer directamente a nuestra función
	timer_ciclo.timeout.connect(cambiar_fase_dia_noche)
	
	# 3. Lo añadimos como hijo del árbol para que funcione
	add_child(timer_ciclo)

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

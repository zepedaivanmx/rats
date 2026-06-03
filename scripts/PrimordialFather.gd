class_name PrimordialFather
extends CharacterBody3D

# ==========================================
# PROPIEDADES UNIVERSALES DE LOS ENEMIGOS
# ==========================================
@export var speed: float = 6.0
@export var max_hp: float = 100.0

var hp: float
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Referencias Globales ---
var arbol_objetivo: Node3D 
var rata_objetivo: Node3D

# --- Variables de Físicas y Estados ---
var empuje_recibido: Vector3 = Vector3.ZERO
var esta_envenenado: bool = false
var esta_sangrando: bool = false
var timer_efectos: float = 0.0

# --- Variables de Muerte y Absorción ---
var esta_muerto: bool = false
var sera_absorbido: bool = false # <--- NUEVA: Define si el árbol se lo come
var esta_pudriendose: bool = false # <--- NUEVA: Define si está fuera del área
var ciclos_pudriendose: int = 0 # <--- NUEVA: Cuenta los ciclos que lleva muerto

@export var velocidad_hundimiento: float = 1.0
@export var profundidad_desaparicion: float = -2.0
@export var radio_absorcion_arbol: float = 20.0


# ==========================================
# INICIALIZACIÓN
# ==========================================
func _ready() -> void:
	hp = max_hp
	# Esperamos un frame para garantizar que el árbol y la rata ya existan en la escena
	await get_tree().physics_frame
	arbol_objetivo = get_tree().get_first_node_in_group("CentralTree")
	rata_objetivo = get_tree().get_first_node_in_group("rats")

# ==========================================
# CICLO FÍSICO PRINCIPAL (CENTRALIZADO)
# ==========================================
func _physics_process(delta: float) -> void:
	# 1. Verificar si está en proceso de muerte
	if esta_muerto:
		if sera_absorbido:
			# Solo se hunde si el árbol lo va a absorber
			position.y -= velocidad_hundimiento * delta
			if position.y <= profundidad_desaparicion:
				finalizar_muerte()
		# Si no será absorbido, se queda pudriéndose, detenemos físicas
		return 

	# 2. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 3. Procesar fricción del empuje (Knockback)
	empuje_recibido = empuje_recibido.move_toward(Vector3.ZERO, delta * 40.0)

	# 4. Decidir movimiento
	if empuje_recibido.length() > 0.5:
		velocity.x = empuje_recibido.x
		velocity.z = empuje_recibido.z
		ha_sido_empujado() 
	else:
		_mover_y_actuar(delta)

	# 5. Aplicar daño por tiempo
	_procesar_estados_alterados(delta)

	# 6. Ejecutar movimiento
	move_and_slide()

# ==========================================
# FUNCIONES VIRTUALES (PARA SOBRESCRIBIR)
# ==========================================
# Las clases hijas deben definir cómo se mueven dentro de esta función
func _mover_y_actuar(_delta: float) -> void:
	pass

# Función por defecto vacía para que los hijos decidan qué hacer al ser empujados
func ha_sido_empujado() -> void:
	pass

# ==========================================
# SISTEMA DE DAÑO Y ESTADOS
# ==========================================
func recibir_impacto(fuerza: Vector3) -> void:
	empuje_recibido = fuerza

func recibir_dano(cantidad: float) -> void:
	if esta_muerto: return
	hp -= cantidad
	if hp <= 0:
		desaparecer()

func aplicar_veneno() -> void:
	esta_envenenado = true

func aplicar_sangrado() -> void:
	esta_sangrando = true

func _procesar_estados_alterados(delta: float) -> void:
	timer_efectos += delta
	if timer_efectos >= 1.0:
		if esta_envenenado:
			recibir_dano(5.0)
		if esta_sangrando and velocity.length() > 0.5:
			recibir_dano(10.0)
		timer_efectos = 0.0

# ==========================================
# SISTEMA DE MUERTE Y ABSORCIÓN
# ==========================================
func desaparecer() -> void:
	if esta_muerto: return
	esta_muerto = true
	ha_sido_empujado()
	
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)

	# --- NUEVA LÓGICA DE DISTANCIA ---
	if arbol_objetivo and is_instance_valid(arbol_objetivo):
		var distancia = global_position.distance_to(arbol_objetivo.global_position)
		if distancia <= radio_absorcion_arbol:
			sera_absorbido = true
		else:
			sera_absorbido = false
			iniciar_putrefaccion() # Comienza el ciclo de descomposición

func finalizar_muerte() -> void:
	# Informa al árbol si murió dentro del área (ahora usamos la bandera sera_absorbido)
	if arbol_objetivo and is_instance_valid(arbol_objetivo) and sera_absorbido:
		if arbol_objetivo.has_method("absorber_cadaver"):
			arbol_objetivo.absorber_cadaver()
				
	queue_free()
# ==========================================
# NUEVO: SISTEMA DE PUTREFACCIÓN (Añadir al final del script)
# ==========================================
func iniciar_putrefaccion() -> void:
	esta_pudriendose = true
	# Conectamos este cadáver a la señal del árbol usando Callable
	if arbol_objetivo.has_signal("ciclo_cambiado"):
		arbol_objetivo.ciclo_cambiado.connect(_on_ciclo_cambiado)

func _on_ciclo_cambiado(_es_de_dia: bool) -> void:
	if not esta_pudriendose: return

	ciclos_pudriendose += 1
	
	match ciclos_pudriendose:
		1:
			atraer_carroneros()
		2:
			generar_nido_insectos()
		3:
			convertirse_en_hongo()

func atraer_carroneros() -> void:
	print("Ciclo 1: Atrayendo carroñeros al cadáver en ", global_position)
	# TODO: Instanciar la escena del enemigo carroñero cerca de este punto
	# Opcional: Cambiar el material/color del cadáver a un tono más oscuro

func generar_nido_insectos() -> void:
	print("Ciclo 2: El cadáver se convierte en nido de insectos en ", global_position)
	# TODO: Cambiar la malla (mesh) a un nido o activar sistema de partículas de moscas
	# TODO: Instanciar área de daño o insectos pequeños alrededor

func convertirse_en_hongo() -> void:
	print("Ciclo 3: El cadáver brota como un hongo en ", global_position)
	# TODO: Instanciar la escena del Hongo (como power-up o trampa)
	# Desconectamos la señal por seguridad antes de borrar el nodo
	if arbol_objetivo.ciclo_cambiado.is_connected(_on_ciclo_cambiado):
		arbol_objetivo.ciclo_cambiado.disconnect(_on_ciclo_cambiado)
	
	queue_free() # El cadáver original desaparece finalmente

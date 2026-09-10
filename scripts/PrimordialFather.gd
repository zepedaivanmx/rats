class_name PrimordialFather  
extends Recolectable # <-- MODIFICADO: Hereda de la clase base de recolección

var es_pesado: bool = true # <-- NUEVO: Indica a la rata que debe ralentizarse
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
var ciclos_pudriendose: int = 0 # <--- NUEVA: Cuenta los ciclos que lleva muerto

@export var velocidad_hundimiento: float = 1.0
@export var profundidad_desaparicion: float = -2.0
@export var radio_absorcion_arbol: float = 20.0


# --- Variables de Muerte y Putrefacción ---
var esta_muerto: bool = false
var sera_absorbido: bool = false
var esta_pudriendose: bool = false

signal ha_muerto(cadaver: Node3D)     # <--- NUEVA SEÑAL: Avisa a las zonas
signal se_ha_pudrido(cadaver: Node3D) # Bandera para la zona
var timer_putrefaccion: Timer

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
	# --- NUEVO: Lógica heredada del transporte ---
	if siendo_transportado and is_instance_valid(transportador):
		var boca = transportador.get_node_or_null("body/Boca")
		if boca:
			global_position = boca.global_position
		return # Salimos de la función para no aplicar gravedad ni IA enemiga
	# ---------------------------------------------
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
	if esta_muerto:
		return
	esta_muerto = true
	ha_sido_empujado()
	# Avisamos a cualquier zona ambiental que lo esté pisando
	ha_muerto.emit(self)
	
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)

	# --- NUEVA LÓGICA DE DISTANCIA ---
	if arbol_objetivo and is_instance_valid(arbol_objetivo):
		var distancia = global_position.distance_to(arbol_objetivo.global_position)
		if distancia <= radio_absorcion_arbol:
			sera_absorbido = true
		else:
			sera_absorbido = false
			#iniciar_putrefaccion() # Comienza el ciclo de descomposición

func finalizar_muerte() -> void:
	# Informa al árbol si murió dentro del área (ahora usamos la bandera sera_absorbido)
	if arbol_objetivo and is_instance_valid(arbol_objetivo) and sera_absorbido:
		if arbol_objetivo.has_method("absorber_cadaver"):
			arbol_objetivo.absorber_cadaver()
				
	queue_free()
# ==========================================
# OVERRIDE DE TRANSPORTE
# ==========================================
func ser_recogido(por_quien: Node3D) -> void:
	super.ser_recogido(por_quien) # Llama la lógica base de Recolectable
	cancelar_putrefaccion()       # Si la rata lo levanta, deja de pudrirse

# ==========================================
# SISTEMA DE PUTREFACCIÓN (Fase 1 - Enemigo)
# ==========================================
func iniciar_putrefaccion() -> void:
	# Solo se pudre si está muerto y no ha empezado el proceso ya
	if esta_pudriendose or not esta_muerto:
		return
	
	esta_pudriendose = true

	# Instanciamos el Timer dinámicamente si no existe
	if not timer_putrefaccion:
		timer_putrefaccion = Timer.new()
		timer_putrefaccion.name = "TimerPutrefaccion"
		timer_putrefaccion.one_shot = true
		timer_putrefaccion.timeout.connect(_on_putrefaccion_completada)
		add_child(timer_putrefaccion)
	
	timer_putrefaccion.start(10.0)
	print("El cadáver " + name + " empieza a pudrirse.")

func cancelar_putrefaccion() -> void:
	if esta_pudriendose and timer_putrefaccion and not timer_putrefaccion.is_stopped():
		timer_putrefaccion.stop()
		esta_pudriendose = false
		print("Putrefacción cancelada. " + name + " fue recogido.")

func _on_putrefaccion_completada() -> void:
	print("El cadáver " + name + " se ha podrido por completo.")
	se_ha_pudrido.emit(self) # Levanta la bandera para notificar a la Zona Ambiental

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
	# 1. Verificar si está en proceso de muerte (Hundimiento)
	if esta_muerto:
		position.y -= velocidad_hundimiento * delta
		if position.y <= profundidad_desaparicion:
			finalizar_muerte()
		return # Detiene cualquier otra lógica de movimiento o físicas

	# 2. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 3. Procesar fricción del empuje (Knockback)
	empuje_recibido = empuje_recibido.move_toward(Vector3.ZERO, delta * 40.0)

	# 4. Decidir movimiento: ¿Está siendo empujado o puede caminar?
	if empuje_recibido.length() > 0.5:
		velocity.x = empuje_recibido.x
		velocity.z = empuje_recibido.z
		ha_sido_empujado() # Si es empujado, debe soltar a la rata (función virtual)
	else:
		# Llama a la función VIRTUAL que cada hijo definirá a su manera
		_mover_y_actuar(delta)

	# 5. Aplicar daño por tiempo (Veneno/Sangrado)
	_procesar_estados_alterados(delta)

	# 6. Ejecutar el movimiento físico en el motor
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
	
	# Desactiva las colisiones para que la rata camine sobre el cadáver sin estorbar
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)

func finalizar_muerte() -> void:
	# Informa al árbol si murió dentro del área de sus raíces
	if arbol_objetivo and is_instance_valid(arbol_objetivo):
		var distancia = global_position.distance_to(arbol_objetivo.global_position)
		if distancia <= radio_absorcion_arbol:
			if arbol_objetivo.has_method("absorber_cadaver"):
				arbol_objetivo.absorber_cadaver()
				
	queue_free()

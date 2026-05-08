extends CharacterBody3D

@export var speed: float = 3.0
@export var fuerza_arrastre: float = 2.0 # Velocidad con la que se lleva a la rata
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var arbol_objetivo: Node3D 
var rata_objetivo: Node3D # Nueva referencia

# --- VARIABLES NUEVAS DE ESTADO ---
var arrastrando_rata: bool = false
var empuje_recibido: Vector3 = Vector3.ZERO
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	await get_tree().physics_frame
	arbol_objetivo = get_tree().get_first_node_in_group("CentralTree")
	rata_objetivo = get_tree().get_first_node_in_group("rats") # Buscamos a la rata
	
	if not arbol_objetivo:
		push_error("Asimilado: No se encontró ningún nodo en el grupo 'CentralTree'")

func _physics_process(delta: float) -> void:
	# --- NUEVO: APLICAR GRAVEDAD ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- REACCIÓN AL COLETAZO ---
	if empuje_recibido.length() > 0.1:
		velocity.x = empuje_recibido.x
		velocity.z = empuje_recibido.z
		move_and_slide() # Procesa colisiones y movimiento en el motor de físicas[cite: 1]
		# Fricción para detener el empuje suavemente
		empuje_recibido = empuje_recibido.lerp(Vector3.ZERO, 5.0 * delta) 
		# Al ser golpeados, soltamos a la rata
		arrastrando_rata = false
		if rata_objetivo and rata_objetivo.has_method("romper_arrastre"):
			rata_objetivo.romper_arrastre()
		return

	if not arbol_objetivo:
		return

	var direction: Vector3 = Vector3.ZERO

	# --- CAPTURA ---
	if rata_objetivo and global_position.distance_to(rata_objetivo.global_position) < 2.0:
		arrastrando_rata = true
	else:
		arrastrando_rata = false

	if arrastrando_rata:
		# Calculamos la dirección ALEJÁNDONOS del árbol
		direction = (global_position - arbol_objetivo.global_position).normalized()
		direction.y = 0
		if rata_objetivo.has_method("aplicar_arrastre"):
			rata_objetivo.aplicar_arrastre(direction * fuerza_arrastre)
		
		# CRÍTICO: El enemigo se mueve a la misma velocidad de arrastre para no soltar a la rata
		velocity.x = direction.x * fuerza_arrastre
		velocity.z = direction.z * fuerza_arrastre
	else:
		# --- NAVEGACIÓN NORMAL ---
		nav_agent.target_position = arbol_objetivo.global_position
		if not nav_agent.is_navigation_finished():
			var next_position: Vector3 = nav_agent.get_next_path_position()
			direction = (next_position - global_position).normalized()
			direction.y = 0 
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	move_and_slide()

# --- NUEVAS FUNCIONES PARA LOS ATAQUES DE LA RATA ---
func recibir_impacto(fuerza: Vector3):
	empuje_recibido = fuerza

func desaparecer():
	# Antes de morir, nos aseguramos de soltar a la rata si la teníamos agarrada
	if arrastrando_rata and rata_objetivo and rata_objetivo.has_method("romper_arrastre"):
		rata_objetivo.romper_arrastre()
	queue_free()

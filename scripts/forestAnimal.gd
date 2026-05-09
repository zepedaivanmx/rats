extends CharacterBody3D

@export var speed: float = 6.0
@export var fuerza_arrastre: float = 5.5 # Velocidad con la que se lleva a la rata
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
	# 1. Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Desacelerar el empuje poco a poco (como si hubiera fricción con el suelo)
	# Reducimos el vector de empuje hacia cero. Puedes subir el 40.0 si quieres que frene más rápido.
	empuje_recibido = empuje_recibido.move_toward(Vector3.ZERO, delta * 40.0)

	if not arbol_objetivo:
		return

	var direction: Vector3 = Vector3.ZERO

	# 3. --- ESTADO DE EMPUJE (KNOCKBACK) ---
	# Si el enemigo recibió un colazo fuerte, pierde el control
	if empuje_recibido.length() > 0.5:
		arrastrando_rata = false # Soltamos a la rata porque estamos volando por los aires
		velocity.x = empuje_recibido.x
		velocity.z = empuje_recibido.z
		
	else:
		# 4. --- LÓGICA NORMAL DE CAPTURA Y NAVEGACIÓN ---
		if rata_objetivo and global_position.distance_to(rata_objetivo.global_position) < 2.0:
			arrastrando_rata = true
		else:
			arrastrando_rata = false

		if arrastrando_rata:
			# Fuerza centrífuga
			direction = (rata_objetivo.global_position - arbol_objetivo.global_position).normalized()
			direction.y = 0 
			
			if rata_objetivo.has_method("aplicar_arrastre"):
				rata_objetivo.aplicar_arrastre(direction * fuerza_arrastre)
			
			velocity.x = direction.x * fuerza_arrastre
			velocity.z = direction.z * fuerza_arrastre
		else:
			# Caminar hacia el árbol
			nav_agent.target_position = rata_objetivo.global_position
			if not nav_agent.is_navigation_finished():
				var next_position: Vector3 = nav_agent.get_next_path_position()
				direction = (next_position - global_position).normalized()
				direction.y = 0 
			
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

	# 5. Finalmente, mover al enemigo usando la velocidad calculada
	move_and_slide()

# --- NUEVAS FUNCIONES PARA LOS ATAQUES DE LA RATA ---
func recibir_impacto(fuerza: Vector3):
	empuje_recibido = fuerza

func desaparecer():
	# Antes de morir, nos aseguramos de soltar a la rata si la teníamos agarrada
	if arrastrando_rata and rata_objetivo and rata_objetivo.has_method("romper_arrastre"):
		rata_objetivo.romper_arrastre()
	queue_free()

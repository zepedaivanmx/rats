extends CharacterBody3D

@export var speed: float = 3.0
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

# Variable para guardar la referencia al árbol
var arbol_objetivo: Node3D 

func _ready() -> void:
	# 1. Esperamos un frame físico para que el NavigationMesh esté 100% cargado
	await get_tree().physics_frame
	
	# 2. Buscamos automáticamente al árbol en la escena usando su grupo
	arbol_objetivo = get_tree().get_first_node_in_group("CentralTree")
	
	# Si por alguna razón no hay árbol en la escena, lanzamos un error en consola para debug
	if not arbol_objetivo:
		push_error("Asimilado: No se encontró ningún nodo en el grupo 'arbol_central'")

func _physics_process(delta: float) -> void:
	# Si no hay árbol al que atacar, detenemos el proceso
	if not arbol_objetivo:
		return

	# 3. Le decimos al agente de navegación dónde está el árbol EXACTAMENTE ahora
	nav_agent.target_position = arbol_objetivo.global_position

	# 4. Si ya llegamos al árbol (o a su base), nos detenemos
	if nav_agent.is_navigation_finished():
		# Aquí más adelante programaremos el daño al árbol
		return

	# 5. Calculamos el siguiente paso seguro en el NavigationMesh
	var next_position: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = (next_position - global_position).normalized()
	
	# Mantenemos la lógica para evitar que vuelen
	direction.y = 0 

	# 6. Movimiento
	velocity = direction * speed
	move_and_slide()

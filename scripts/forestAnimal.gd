extends PrimordialFather

@export var fuerza_arrastre: float = 5.5
var arrastrando_rata: bool = false
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

# Sobrescribimos la función virtual del padre para definir su movimiento específico
func _mover_y_actuar(_delta: float) -> void:
	if not arbol_objetivo or not rata_objetivo: return
	
	var direction: Vector3 = Vector3.ZERO
	
	# Lógica de Captura
	if global_position.distance_to(rata_objetivo.global_position) < 2.0:
		arrastrando_rata = true
	else:
		arrastrando_rata = false
		
	# Lógica de Arrastre o Persecución
	if arrastrando_rata:
		direction = (rata_objetivo.global_position - arbol_objetivo.global_position).normalized()
		direction.y = 0 
		if rata_objetivo.has_method("aplicar_arrastre"):
			rata_objetivo.aplicar_arrastre(direction * fuerza_arrastre)
		velocity.x = direction.x * fuerza_arrastre
		velocity.z = direction.z * fuerza_arrastre
	else:
		nav_agent.target_position = rata_objetivo.global_position
		if not nav_agent.is_navigation_finished():
			var next_position: Vector3 = nav_agent.get_next_path_position()
			direction = (next_position - global_position).normalized()
			direction.y = 0 
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

# Sobrescribimos la regla de qué pasa cuando es empujado o muere
func ha_sido_empujado() -> void:
	arrastrando_rata = false
	if rata_objetivo and rata_objetivo.has_method("romper_arrastre"):
		rata_objetivo.romper_arrastre()

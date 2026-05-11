extends CharacterBody3D # O Node3D / Area3D, dependiendo de qué nodo raíz usaste

@export var velocidad_avance: float = 5.0
@export var velocidad_rotacion: float = 2.0 # Qué tan cerrado es el círculo

# Variables de gravedad por si tu serpiente es un CharacterBody3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	# 1. Aplicar gravedad si está en el aire (opcional, si es un CharacterBody3D)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Girar constantemente sobre su eje Y (el eje que apunta hacia arriba)
	rotate_y(velocidad_rotacion * delta)

	# 3. Caminar hacia "adelante"
	# En Godot 3D, el "frente" local de un objeto es su eje -Z
	var direccion_frente = -transform.basis.z.normalized()
	
	velocity.x = direccion_frente.x * velocidad_avance
	velocity.z = direccion_frente.z * velocidad_avance
	
	move_and_slide()
	
func desaparecer():
	# Esta es la función que tu rata llama al morderla
	queue_free()

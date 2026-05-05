extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Obtenemos la gravedad global del proyecto para mantener coherencia física
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Hacemos referencia al nodo visual. Asegúrate de que el nombre coincida exactamente con tu nodo.
@onready var visual_mesh = $body

func _physics_process(delta: float) -> void:
	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Mecánica de Salto
	# Utilizamos "ui_accept" (usualmente la barra espaciadora por defecto)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Obtener el vector de entrada (Input)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Calculamos la dirección en el plano XZ global, ignorando la rotación del cuerpo
	var direction := (Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 4. Aplicar Movimiento y Rotación Visual
	if direction:
		# Movimiento rígido y responsivo, ideal para tu género
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Rotamos SOLAMENTE la malla visual hacia la dirección de movimiento
		# El valor '15' define la velocidad de giro; ajústalo a tu gusto
		var target_rotation = atan2(direction.x, direction.z)
		visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, target_rotation, 15 * delta)
	else:
		# Fricción instantánea para detenerse en seco
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Función interna de Godot que procesa colisiones y movimiento
	move_and_slide()

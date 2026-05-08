extends CharacterBody3D

@onready var area_mordida = $AreaMordida
@onready var area_colazo = $AreaColazo

func _input(event):
	# Mordida (Ejemplo: Click izquierdo)
	if event.is_action_pressed("ataque_primario"):
		ejecutar_mordida()
	
	# Colazo (Ejemplo: Click derecho o Tecla E)
	if event.is_action_pressed("ataque_secundario"):
		ejecutar_colazo()

func ejecutar_mordida():
	for body in area_mordida.get_overlapping_bodies():
		if body.has_method("desaparecer"):
			body.desaparecer()

func ejecutar_colazo():
	for body in area_colazo.get_overlapping_bodies():
		if body is CharacterBody3D:
			# Calculamos la dirección opuesta a la rata
			var empuje = (body.global_position - global_position).normalized() * 15.0
			if body.has_method("recibir_impacto"):
				body.recibir_impacto(empuje)

# Lógica del Aura (Conecta las señales body_entered y body_exited del AreaAura)
func _on_area_aura_body_entered(body):
	if body.is_in_group("asimilados"):
		body.speed = body.base_speed * 0.5 # Reduce velocidad al 50%

func _on_area_aura_body_exited(body):
	if body.is_in_group("asimilados"):
		body.speed = body.base_speed
		
		
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
	
	

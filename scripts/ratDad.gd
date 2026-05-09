extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visual_mesh = $body
@onready var area_mordida = $biteArea
@onready var area_colazo = $tailArea
@onready var area_contacto = $auraArea

# --- VARIABLES DE ARRASTRE Y ATAQUES ---
var vector_arrastre: Vector3 = Vector3.ZERO
var cooldown_mordida: float = 0.0
var cooldown_colazo: float = 0.0
var tiempo_mordida: float = 12.0
var tiempo_colazo: float = 6.0

func _physics_process(delta: float) -> void:
	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Mecánica de Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Obtener el vector de entrada (Input en 8 direcciones)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 4. Calcular velocidad de movimiento base por Input
	var target_velocity_x = 0.0
	var target_velocity_z = 0.0

	if direction:
		target_velocity_x = direction.x * SPEED
		target_velocity_z = direction.z * SPEED
		
		# --- ROTACIÓN INDEPENDIENTE DEL ARRASTRE ---
		# La rotación visual SOLO responde a la dirección del input
		var target_rotation = atan2(direction.x, direction.z)
		visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, target_rotation, 15 * delta)
	else:
		# Si el jugador no presiona nada, la velocidad de input tiende a cero
		target_velocity_x = move_toward(velocity.x - vector_arrastre.x, 0, SPEED)
		target_velocity_z = move_toward(velocity.z - vector_arrastre.z, 0, SPEED)

	# 5. --- LA MAGIA: SUMAR EL ARRASTRE AL INPUT ---
	# La velocidad final es lo que el jugador intenta moverse + la fuerza centrífuga que le aplican
	velocity.x = target_velocity_x + vector_arrastre.x
	velocity.z = target_velocity_z + vector_arrastre.z

	move_and_slide()

	# --- RUTINA DE ATAQUES AUTOMÁTICOS ---
	cooldown_mordida -= delta
	if cooldown_mordida <= 0:
		ejecutar_mordida()
		cooldown_mordida = tiempo_mordida

	cooldown_colazo -= delta
	if cooldown_colazo <= 0:
		ejecutar_colazo()
		cooldown_colazo = tiempo_colazo
		

# --- LÓGICA DE ATAQUES MODIFICADA ---
func ejecutar_mordida():
	# Desaparece de uno en uno usando 'break' para detener el ciclo tras el primer impacto
	for body in area_mordida.get_overlapping_bodies():
		if body.has_method("desaparecer"):
			body.desaparecer()
			break 

func ejecutar_colazo():
	var acerto_golpe = false
	for body in area_colazo.get_overlapping_bodies():
		if body is CharacterBody3D:
			var empuje = (body.global_position - global_position).normalized() * 15.0
			
			if body.has_method("recibir_impacto"):
				body.recibir_impacto(empuje)
				acerto_golpe = true
	
	# Si golpeamos a alguien, nos liberamos del arrastre
	if acerto_golpe:
		romper_arrastre()

# --- MÉTODOS DE CONTROL DE ARRASTRE ---
func aplicar_arrastre(fuerza: Vector3):
	vector_arrastre = fuerza

func romper_arrastre():
	vector_arrastre = Vector3.ZERO



func _on_aura_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.speed = body.base_speed * 0.5 


func _on_aura_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.speed = body.base_speed

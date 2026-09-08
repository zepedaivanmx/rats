class_name Recolectable
extends CharacterBody3D

var transportador: Node3D = null
var siendo_transportado: bool = false
@export var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	if not is_in_group("recolectables"):
		add_to_group("recolectables")
	
	# Llamada a la función virtual que usarán los hijos
	_inicializar_recolectable()

func _physics_process(delta: float) -> void:
	if siendo_transportado and is_instance_valid(transportador):
		# Se pega visualmente al Marker3D que pusimos en la cabeza de la rata
		var boca = transportador.get_node_or_null("body/Boca")
		if boca:
			global_position = boca.global_position
		else:
			# Fallback por si olvidas poner el Marker3D
			global_position = transportador.global_position + Vector3(0, 0.5, 1.0)
	else:
		# Lógica de físicas normales cuando está tirado en el suelo
		if not is_on_floor():
			velocity.y -= gravedad * delta
		else:
			velocity.y = 0
			
		# Fricción
		velocity.x = move_toward(velocity.x, 0, delta * 5.0)
		velocity.z = move_toward(velocity.z, 0, delta * 5.0)
		move_and_slide()

# --- FUNCIONES VIRTUALES PARA LOS HIJOS ---
func _inicializar_recolectable() -> void:
	pass

# --- LÓGICA DE TRANSPORTE ---
func ser_recogido(por_quien: Node3D) -> void:
	siendo_transportado = true
	transportador = por_quien
	# Apagamos colisiones físicas para que no choque contra la rata al moverse
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)

func ser_soltado(posicion_soltado: Vector3) -> void:
	siendo_transportado = false
	transportador = null
	global_position = posicion_soltado
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", false)

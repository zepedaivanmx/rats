class_name Recolectable
extends CharacterBody3D

signal recogido(por_quien: Node3D)
signal soltado(recolectable: Recolectable)

enum ModoRecogida { BOCA, INVENTARIO }

const CAPA_CADAVER := 1 << 4        # Capa 5
const CAPA_RECOLECTABLE := 1 << 5   # Capa 6

@export var modo_recogida: ModoRecogida = ModoRecogida.BOCA
@export var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var valor: int = 1
var transportador: Node3D = null
var siendo_transportado: bool = false
var _capa_guardada: int
var _mascara_guardada: int

func _ready() -> void:
	add_to_group("recolectables")
	_inicializar_recolectable()

func _physics_process(delta: float) -> void:
	if siendo_transportado:
		if is_instance_valid(transportador):
			global_position = _obtener_punto_agarre()
		else:
			ser_soltado(global_position)
		return
	_procesar_fisica_libre(delta)

func _inicializar_recolectable() -> void:
	pass

func puede_ser_recogido() -> bool:
	return not siendo_transportado

func _procesar_fisica_libre(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta
	else:
		velocity.y = 0
	velocity.x = move_toward(velocity.x, 0, delta * 5.0)
	velocity.z = move_toward(velocity.z, 0, delta * 5.0)
	move_and_slide()

func _obtener_punto_agarre() -> Vector3:
	var boca = transportador.get_node_or_null("body/Boca")
	if boca:
		return boca.global_position
	return transportador.global_position + Vector3(0, 0.5, 1.0)

func ser_recogido(por_quien: Node3D) -> void:
	transportador = por_quien
	_capa_guardada = collision_layer
	_mascara_guardada = collision_mask
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	if modo_recogida == ModoRecogida.INVENTARIO:
		visible = false
		set_physics_process(false)
	else:
		siendo_transportado = true
	recogido.emit(por_quien)

func ser_soltado(posicion_soltado: Vector3) -> void:
	siendo_transportado = false
	transportador = null
	global_position = posicion_soltado
	collision_layer = _capa_guardada
	collision_mask = _mascara_guardada
	visible = true
	set_physics_process(true)
	soltado.emit(self)
	_notificar_zonas()

func _notificar_zonas() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	for zona in get_tree().get_nodes_in_group("zonas_ambientales"):
		if zona.overlaps_body(self):
			zona.recibir_recolectable(self)
			break

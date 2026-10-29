class_name RataLanzapiedras
extends AliadoBase

@export var piedra_scene: PackedScene
@export var alcance_torre: float = 14.0

@onready var visual: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _inicializar_aliado() -> void:
	velocidad = 8.0
	hp_maximo = 60.0
	hp = hp_maximo
	rango_ataque = alcance_torre
	intervalo_ataque = 2.0
	interactuable_por_rata = false
	es_estatico = true

func activar_en_raiz_alta(pos_cima: Vector3) -> void:
	activar_desde_bosque_profundo(pos_cima, pos_cima)
	estado_actual = EstadoAliado.GUARDANDO_POSICION
	orden_actual = EstadoAliado.GUARDANDO_POSICION
	if is_instance_valid(visual):
		visual.visible = true

func _buscar_enemigos_en_area() -> void:
	var mas_cercano: Node3D = null
	var min_dist := alcance_torre
	var mi_pos := Vector2(global_position.x, global_position.z)
	
	for enemigo in get_tree().get_nodes_in_group("enemy"):
		if not _es_enemigo_valido(enemigo):
			continue
		var d := mi_pos.distance_to(Vector2(enemigo.global_position.x, enemigo.global_position.z))
		if d <= min_dist:
			min_dist = d
			mas_cercano = enemigo
	
	if is_instance_valid(mas_cercano):
		enemigo_objetivo = mas_cercano
		estado_actual = EstadoAliado.ATACANDO

func _ejecutar_ataque_especifico(objetivo: Node3D) -> void:
	if not piedra_scene or not is_instance_valid(objetivo):
		return
	
	var instancia := piedra_scene.instantiate()
	get_tree().current_scene.add_child(instancia)
	
	# En projectile.tscn el RigidBody3D con colisión y script es hijo de otro RigidBody3D
	var cuerpo_piedra: RigidBody3D = null
	if instancia.get_node_or_null("RigidBody3D") is RigidBody3D:
		cuerpo_piedra = instancia.get_node("RigidBody3D")
		cuerpo_piedra.top_level = true
	elif instancia is RigidBody3D:
		cuerpo_piedra = instancia
	
	if not is_instance_valid(cuerpo_piedra):
		return
	
	cuerpo_piedra.global_position = global_position + Vector3(0.0, 0.8, 0.0)
	var dir := cuerpo_piedra.global_position.direction_to(objetivo.global_position)
	var dist := cuerpo_piedra.global_position.distance_to(objetivo.global_position)
	var impulso := (dir * (dist * 2.2)) + Vector3(0.0, dist * 0.65 + 2.5, 0.0)
	cuerpo_piedra.apply_central_impulse(impulso)

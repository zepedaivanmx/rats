class_name RaizZona
extends ZonaAmbiental

@export var rata_lanzapiedras_scene: PackedScene
@export var radio_nube_esporas: float = 4.5
@export var dano_esporas_por_segundo: float = 12.0

var es_raiz_alta: bool = false
var tiene_defensa_instalada: bool = false
var nube_esporas_activa: bool = false
var timer_esporas: Timer

@onready var malla_raiz: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _inicializar_zona() -> void:
	tipo_de_zona = TipoZona.RAICES
	if not rata_lanzapiedras_scene and ResourceLoader.exists("res://entities/rat_ally.tscn"):
		rata_lanzapiedras_scene = load("res://entities/rat_ally.tscn")

func acepta(obj: Node3D) -> bool:
	if not is_instance_valid(obj) or tiene_defensa_instalada:
		return false
	
	# 1. Cadáver: solo si todavía es raíz baja
	if obj is PrimordialFather and obj.esta_muerto and not obj.en_gestacion:
		return not es_raiz_alta
	
	# 2. Hongo: se acepta tanto en raíz baja como en raíz alta
	if obj.is_in_group("hongo"):
		return true
	
	# 3. Mineral: requiere que la raíz ya sea una raíz alta
	if obj.is_in_group("mineral"):
		return es_raiz_alta
	
	return false

func _al_completar_gestacion(cadaver: Node3D) -> void:
	if is_instance_valid(cadaver):
		cadaver.queue_free()
	
	es_raiz_alta = true
	if is_instance_valid(malla_raiz):
		malla_raiz.scale.y *= 3.0
		malla_raiz.position.y += 1.0
	print(name, ": ¡La raíz creció a Raíz Alta!")

func _al_recibir_recurso_recolectable(recurso: Recolectable) -> void:
	if tiene_defensa_instalada:
		return
	
	if recurso.is_in_group("mineral") and es_raiz_alta:
		tiene_defensa_instalada = true
		recurso.queue_free()
		_desplegar_rata_lanzapiedras()
	elif recurso.is_in_group("hongo"):
		tiene_defensa_instalada = true
		recurso.queue_free()
		_activar_nube_esporas()

func _desplegar_rata_lanzapiedras() -> void:
	if not rata_lanzapiedras_scene:
		push_warning("RaizZona: falta asignar rata_lanzapiedras_scene")
		return
	
	var instancia := rata_lanzapiedras_scene.instantiate()
	get_tree().current_scene.add_child(instancia)
	var cuerpo: Node3D = instancia if instancia is AliadoBase else instancia.get_node_or_null("CharacterBody3D")
	if is_instance_valid(cuerpo) and cuerpo.has_method("activar_en_raiz_alta"):
		cuerpo.activar_en_raiz_alta(global_position + Vector3(0.0, 2.2, 0.0))

func _activar_nube_esporas() -> void:
	nube_esporas_activa = true
	print(name, ": ¡Nube de esporas venenosas activada en la raíz!")
	
	# Representación visual translúcida de la nube de esporas
	var nube_visual := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = radio_nube_esporas
	esfera.height = 2.0
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.55, 0.15, 0.85, 0.35)
	esfera.material = mat
	nube_visual.mesh = esfera
	nube_visual.position = Vector3(0.0, 1.0, 0.0)
	add_child(nube_visual)
	
	# Pulso periódico de veneno y daño de área
	timer_esporas = Timer.new()
	timer_esporas.wait_time = 1.0
	timer_esporas.autostart = true
	timer_esporas.timeout.connect(_aplicar_pulso_esporas)
	add_child(timer_esporas)

func _aplicar_pulso_esporas() -> void:
	for enemigo in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemigo) or enemigo.get("esta_muerto") == true:
			continue
		if global_position.distance_to(enemigo.global_position) <= radio_nube_esporas:
			if enemigo.has_method("aplicar_veneno"):
				enemigo.aplicar_veneno()
			if enemigo.has_method("recibir_dano"):
				enemigo.recibir_dano(dano_esporas_por_segundo)

class_name ZonaAmbiental
extends Area3D

enum TipoZona { NINGUNA, ARBOL, RAICES, CHARCO, PASTO, ZARZAS, ARENA }

@export var tipo_de_zona: TipoZona = TipoZona.NINGUNA
@export var entrega_automatica: bool = true
@export var reclama_cadaveres: bool = true
@export var duracion_gestacion: float = 10.0


func _ready() -> void:
	add_to_group("zonas_ambientales")
	# Detecta capa 1 (personajes), capa 5 (cadáveres) y capa 6 (minerales/hongos)
	collision_mask |= 1 | Recolectable.CAPA_CADAVER | Recolectable.CAPA_RECOLECTABLE
	_ajustar_volumen_deteccion()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	_inicializar_zona()

func _inicializar_zona() -> void:
	pass

# Garantiza que el cilindro de colisión tenga altura suficiente para detectar a la rata (y = 0.84)
func _ajustar_volumen_deteccion() -> void:
	for child in get_children():
		if child is CollisionShape3D and child.shape is CylinderShape3D:
			var cilindro := child.shape as CylinderShape3D
			if cilindro.height < 2.5:
				cilindro.height = 2.5
				child.position.y = 1.0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("rats"):
		if entrega_automatica:
			var obj = body.get("objeto_cargado")
			if is_instance_valid(obj) and acepta(obj):
				var soltado = body.soltar_objeto()
				if is_instance_valid(soltado):
					recibir_recolectable(soltado)
		return
	
	if body is PrimordialFather:
		if body.esta_muerto:
			recibir_recolectable(body)
		elif not body.ha_muerto.is_connected(_on_enemigo_murio_en_zona):
			body.ha_muerto.connect(_on_enemigo_murio_en_zona)
	elif body is Recolectable:
		recibir_recolectable(body)

func _on_body_exited(body: Node3D) -> void:
	if body is PrimordialFather and body.ha_muerto.is_connected(_on_enemigo_murio_en_zona):
		body.ha_muerto.disconnect(_on_enemigo_murio_en_zona)

func _on_enemigo_murio_en_zona(cadaver: Node3D) -> void:
	recibir_recolectable(cadaver)

# --- API PÚBLICA POLIMÓRFICA ---
func acepta(obj: Node3D) -> bool:
	return obj is PrimordialFather and obj.esta_muerto and not obj.en_gestacion

func recibir_recolectable(obj: Node3D) -> void:
	if not is_instance_valid(obj) or not acepta(obj):
		return
	
	# Caso 1: Es un cadáver de enemigo -> inicia putrefacción/gestación
	if obj is PrimordialFather:
		var cadaver := obj as PrimordialFather
		cadaver.en_gestacion = true
		if reclama_cadaveres:
			cadaver.reclamar_por_zona()
		if not cadaver.se_ha_pudrido.is_connected(_on_cadaver_podrido):
			cadaver.se_ha_pudrido.connect(_on_cadaver_podrido, CONNECT_ONE_SHOT)
		cadaver.iniciar_putrefaccion(duracion_gestacion)
	# Caso 2: Es un recurso recolectable (Mineral u Hongo) -> efecto inmediato
	elif obj is Recolectable:
		_al_recibir_recurso_recolectable(obj as Recolectable)

func _on_cadaver_podrido(cadaver: Node3D) -> void:
	if is_instance_valid(cadaver):
		_al_completar_gestacion(cadaver)

# --- HOOKS VIRTUALES PARA LAS CLASES HIJAS ---
func _al_completar_gestacion(cadaver: Node3D) -> void:
	if is_instance_valid(cadaver):
		cadaver.queue_free()

func _al_recibir_recurso_recolectable(recurso: Recolectable) -> void:
	if is_instance_valid(recurso):
		recurso.queue_free()

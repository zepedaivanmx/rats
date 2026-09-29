class_name ZonaAmbiental extends Area3D

enum TipoZona { NINGUNA, ARBOL, RAICES, CHARCO, PASTO, ZARZAS, ARENA }
@export var tipo_de_zona: TipoZona = TipoZona.NINGUNA
@export var entrega_automatica: bool = true   # Opción C. En false: solo suelta manual
@export var reclama_cadaveres: bool = true    # Prioridad sobre la absorción del árbol
@export var duracion_gestacion: float = 10.0

func _ready() -> void:
	add_to_group("zonas_ambientales")
	collision_mask |= Recolectable.CAPA_CADAVER # ver cadáveres
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("rats"):
		if entrega_automatica:
			var obj = body.get("objeto_cargado")
			if is_instance_valid(obj) and acepta(obj):
				body.soltar_objeto() # ser_soltado() notificará a la zona
		return
	if body is PrimordialFather:
		if body.esta_muerto:
			recibir_recolectable(body)
		elif not body.ha_muerto.is_connected(_on_enemigo_murio_en_zona):
			body.ha_muerto.connect(_on_enemigo_murio_en_zona)

func _on_body_exited(body: Node3D) -> void:
	if body is PrimordialFather and body.ha_muerto.is_connected(_on_enemigo_murio_en_zona):
		body.ha_muerto.disconnect(_on_enemigo_murio_en_zona)

func _on_enemigo_murio_en_zona(cadaver: Node3D) -> void:
	recibir_recolectable(cadaver)

# --- API PÚBLICA (la usa Recolectable al soltarse) ---
func acepta(obj: Node3D) -> bool:
	return obj is PrimordialFather and obj.esta_muerto and not obj.en_gestacion

func recibir_recolectable(obj: Node3D) -> void:
	if not acepta(obj):
		return # idempotente: evita doble procesado
	var cadaver := obj as PrimordialFather
	cadaver.en_gestacion = true
	if reclama_cadaveres:
		cadaver.reclamar_por_zona()
	cadaver.se_ha_pudrido.connect(_on_cadaver_podrido, CONNECT_ONE_SHOT)
	cadaver.iniciar_putrefaccion()

func _on_cadaver_podrido(cadaver: Node3D) -> void:
	get_tree().create_timer(duracion_gestacion).timeout.connect(
		func(): if is_instance_valid(cadaver): _al_completar_gestacion(cadaver))

# --- HOOK VIRTUAL: los hijos sobrescriben SOLO esto ---
func _al_completar_gestacion(cadaver: Node3D) -> void:
	cadaver.queue_free()

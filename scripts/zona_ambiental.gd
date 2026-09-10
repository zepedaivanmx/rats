class_name ZonaAmbiental extends Area3D

# Enumerador para definir la identidad de la zona desde el Inspector
enum TipoZona { NINGUNA, ARBOL, RAICES, CHARCO, PASTO, ZARZAS, ARENA }
@export var tipo_de_zona: TipoZona = TipoZona.NINGUNA

# ==========================================
# DETECCIÓN AUTOMÁTICA DE CADÁVERES
# ==========================================
func _ready() -> void:
	add_to_group("zonas_ambientales")
	# Conectamos las señales nativas del Area3D a nuestro script
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	# Ignorar cualquier cosa que no sea un enemigo
	if not body.is_in_group("enemy"):
		return
		
	# CASO A: Entró un cadáver (Ej. La rata lo soltó aquí o cayó muerto)
	if body.get("esta_muerto") == true:
		procesar_cadaver(body)
	# CASO B: Entró un enemigo vivo. Lo vigilamos.
	else:
		if body.has_signal("ha_muerto") and not body.is_connected("ha_muerto", _on_enemigo_murio_en_zona):
			body.ha_muerto.connect(_on_enemigo_murio_en_zona)

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("enemy"):
		return
		
	# Si el enemigo sale de la zona vivo, dejamos de vigilarlo
	if body.has_signal("ha_muerto") and body.is_connected("ha_muerto", _on_enemigo_murio_en_zona):
		body.ha_muerto.disconnect(_on_enemigo_murio_en_zona)

func _on_enemigo_murio_en_zona(cadaver: Node3D) -> void:
	# Esta función se dispara automáticamente si el enemigo muere pisando esta zona
	print("Enemigo murió orgánicamente dentro de la zona: ", name)
	procesar_cadaver(cadaver)

# ==========================================
# LÓGICA DE ZONAS (Fase 2 - Generación)
# ==========================================
func procesar_cadaver(cadaver: Node3D) -> void:
	# Verificamos que el nodo tenga la capacidad de pudrirse
	if cadaver.has_method("iniciar_putrefaccion"):
		# 1. Escuchamos la bandera del cadáver. Usamos is_connected para evitar duplicados.
		if not cadaver.is_connected("se_ha_pudrido", _iniciar_timer_generacion):
			cadaver.se_ha_pudrido.connect(_iniciar_timer_generacion)
		
		# 2. Le ordenamos al cadáver que empiece su reloj interno de 10s
		cadaver.iniciar_putrefaccion()

func _iniciar_timer_generacion(cadaver: Node3D) -> void:
	# Desconectamos para evitar llamadas múltiples si entran varios cadáveres
	cadaver.se_ha_pudrido.disconnect(_iniciar_timer_generacion)
	
	print("Zona " + name + " detectó un cadáver podrido. Iniciando gestación (10s)...")
	
	# La zona crea SU PROPIO temporizador para la Fase 2 (generar hongo/lagarto)
	var timer_generacion = Timer.new()
	timer_generacion.one_shot = true
	add_child(timer_generacion)
	
	# Pasamos el cadáver y el timer como argumentos
	timer_generacion.timeout.connect(_resolver_efecto_zona.bind(cadaver, timer_generacion))
	timer_generacion.start(10.0)

func _resolver_efecto_zona(cadaver: Node3D, timer_usado: Timer) -> void:
	timer_usado.queue_free() # Limpiamos el nodo Timer de la RAM
	
	# Validación de seguridad: Si la rata se robó el cadáver en el último segundo, abortamos.
	if not is_instance_valid(cadaver) or not cadaver.esta_pudriendose:
		return 

	# Ejecutamos el efecto según el Inspector
	match tipo_de_zona:
		TipoZona.ARBOL: _efecto_arbol(cadaver)
		TipoZona.RAICES: _efecto_raices(cadaver)
		TipoZona.CHARCO: _efecto_charco(cadaver)
		TipoZona.PASTO: _efecto_pasto(cadaver)
		TipoZona.ZARZAS: _efecto_zarzas(cadaver)
		TipoZona.ARENA: _efecto_arena(cadaver)
		_:
			print("El cadáver cayó en una zona no definida.")
			cadaver.queue_free()

# --- MÉTODOS DE RESOLUCIÓN (Listos para sobrescribirse en scripts hijos si es necesario) ---

func _efecto_arbol(cadaver: Node3D) -> void:
	var arbol = get_tree().get_first_node_in_group("CentralTree")
	if arbol and arbol.has_method("absorber_cadaver"):
		arbol.absorber_cadaver()
	cadaver.queue_free()

func _efecto_raices(cadaver: Node3D) -> void:
	print("Haciendo crecer raíces altas para nuevas defensas...")
	# TODO: Lógica para instanciar un nodo de "Slot de Defensa" en esta posición
	cadaver.queue_free()

func _efecto_charco(cadaver: Node3D) -> void:
	print("El cadáver se pudre en el agua. Brotando Hongos...")
	# TODO: Instanciar la escena del Hongo (recolectable) en cadaver.global_position
	cadaver.queue_free()

func _efecto_pasto(cadaver: Node3D) -> void:
	print("Creciendo pasto alto, atrayendo escarabajos...")
	# TODO: Instanciar la escena del Escarabajo (recolectable)
	cadaver.queue_free()

func _efecto_zarzas(cadaver: Node3D) -> void:
	print("Las zarzas consumen la carne. Obteniendo retoños...")
	# TODO: Instanciar Retoño de Zarza (recolectable)
	cadaver.queue_free()

func _efecto_arena(cadaver: Node3D) -> void:
	print("El olor en la arena atrae lagartos...")
	# TODO: Instanciar Lagarto (recolectable)
	cadaver.queue_free()
	
	

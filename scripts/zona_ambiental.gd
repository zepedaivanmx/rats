class_name ZonaAmbiental extends Area3D

# Enumerador para definir la identidad de la zona desde el Inspector
enum TipoZona { NINGUNA, ARBOL, RAICES, CHARCO, PASTO, ZARZAS, ARENA }
@export var tipo_de_zona: TipoZona = TipoZona.NINGUNA

func _ready() -> void:
	# Aseguramos que la zona pertenezca a un grupo reconocible para interacciones orgánicas
	add_to_group("zonas_ambientales")

# Función base que recibe el cadáver y delega el efecto según el tipo de zona
func procesar_cadaver(cadaver: Node3D) -> void:
	match tipo_de_zona:
		TipoZona.ARBOL:
			_efecto_arbol(cadaver)
		TipoZona.RAICES:
			_efecto_raices(cadaver)
		TipoZona.CHARCO:
			_efecto_charco(cadaver)
		TipoZona.PASTO:
			_efecto_pasto(cadaver)
		TipoZona.ZARZAS:
			_efecto_zarzas(cadaver)
		TipoZona.ARENA:
			_efecto_arena(cadaver)
		_:
			print("El cadáver cayó en una zona no definida.")

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

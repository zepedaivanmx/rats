# Archivo: scripts/torre_zona.gd
class_name TorreZona extends ZonaAmbiental

@export var rata_lanzapiedras_scene: PackedScene
var torre_ocupada: bool = false # Para evitar que trague minerales infinitos

func _ready() -> void:
	super()
	tipo_de_zona = TipoZona.RAICES

# 1. SOBRESCRITURA: Regla de qué acepta la torre. Solo minerales y si está vacía.
func acepta(obj: Node3D) -> bool:
	return obj.is_in_group("mineral") and not torre_ocupada

# 2. SOBRESCRITURA: Al recibir el objeto, no hay putrefacción. Es inmediato.
func recibir_recolectable(obj: Node3D) -> void:
	if not acepta(obj):
		return
		
	torre_ocupada = true
	obj.queue_free() # Consumo instantáneo del mineral
	
	# Llamamos directamente a la gestación sin usar timers
	_al_completar_gestacion(null)

# 3. SOBRESCRITURA: Instanciación en la madriguera y orden de movimiento
func _al_completar_gestacion(_cadaver: Node3D = null) -> void:
	if not rata_lanzapiedras_scene:
		push_warning("TorreZona: falta asignar rata_lanzapiedras_scene")
		return
		
	var rata_aliada = rata_lanzapiedras_scene.instantiate()
	get_tree().current_scene.add_child(rata_aliada)
	
	# Buscamos el Árbol (madriguera) para hacer spawn ahí
	var arbol = get_tree().get_first_node_in_group("CentralTree")
	if arbol:
		# Spawn cerca del árbol
		rata_aliada.global_position = arbol.global_position + Vector3(1.5, 0.5, 0)
	else:
		rata_aliada.global_position = self.global_position # Respaldo si no hay árbol
		
	# Le damos la orden a la Rata de caminar hacia la coordenada de esta Torre
	if rata_aliada.has_method("caminar_hacia"):
		rata_aliada.caminar_hacia(self.global_position)

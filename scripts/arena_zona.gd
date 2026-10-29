class_name ArenaZona
extends ZonaAmbiental

@export var distancia_bosque_profundo: float = 35.0
var animal_habilitado: bool = false
var gestando_animal: bool = false

@onready var lagarto_unico: AliadoBase = get_node_or_null("Lagarto")

func _inicializar_zona() -> void:
	tipo_de_zona = TipoZona.ARENA

# Solo acepta 1 cadáver en toda la partida (bloquea desde que inicia la gestación)
func acepta(obj: Node3D) -> bool:
	return not animal_habilitado and not gestando_animal and super(obj)

func recibir_recolectable(obj: Node3D) -> void:
	if acepta(obj):
		gestando_animal = true
		super(obj)

func _al_completar_gestacion(cadaver: Node3D) -> void:
	if is_instance_valid(cadaver):
		cadaver.queue_free()
	
	if animal_habilitado or not is_instance_valid(lagarto_unico):
		return
	
	animal_habilitado = true
	var pos_spawn := _calcular_pos_bosque_profundo()
	lagarto_unico.activar_desde_bosque_profundo(pos_spawn, self.global_position)
	
	
func _calcular_pos_bosque_profundo() -> Vector3:
	var arbol := get_tree().get_first_node_in_group("CentralTree")
	# Declaramos explícitamente el tipo Vector3 para evitar errores de inferencia en el parser
	var centro: Vector3 = Vector3.ZERO
	if is_instance_valid(arbol):
		centro = arbol.global_position
		
	var dir_zona := (global_position - centro)
	dir_zona.y = 0.0
	dir_zona = dir_zona.normalized() if dir_zona.length_squared() > 0.01 else Vector3.LEFT
	return centro + (dir_zona * distancia_bosque_profundo) + Vector3(0.0, 0.5, 0.0)

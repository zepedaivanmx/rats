class_name Charco
extends ZonaAmbiental

@export var hongo_scene: PackedScene
@export var sapo_boss_scene: PackedScene
@export var cantidad_hongos: int = 3
@export var radio_anillo: float = 2.2
@export var cadaveres_para_sapo: int = 15

var cadaveres_acumulados: int = 0
var sapo_invocado: bool = false

func _inicializar_zona() -> void:
	tipo_de_zona = TipoZona.CHARCO

func _al_completar_gestacion(cadaver: Node3D) -> void:
	if is_instance_valid(cadaver):
		cadaver.queue_free()
	
	cadaveres_acumulados += 1
	print("Charco: Cadáveres acumulados = ", cadaveres_acumulados, "/", cadaveres_para_sapo)
	
	# 1. Generar hongos recolectables
	if hongo_scene:
		for i in cantidad_hongos:
			var ang := TAU * i / cantidad_hongos + randf_range(-0.3, 0.3)
			var hongo = hongo_scene.instantiate()
			get_tree().current_scene.add_child(hongo)
			hongo.global_position = global_position + Vector3(cos(ang) * radio_anillo, 0.5, sin(ang) * radio_anillo)
	
	# 2. Verificar si se alcanzó el umbral de 15 cadáveres para despertar al Sapo
	if cadaveres_acumulados >= cadaveres_para_sapo and not sapo_invocado:
		_emerger_jefe_sapo()

func _emerger_jefe_sapo() -> void:
	sapo_invocado = true
	print("¡15 CADÁVERES EN EL CHARCO! ¡EL JEFE SAPO HA EMERGIDO DEL CENTRO DEL CHARCO!")
	if sapo_boss_scene:
		var sapo = sapo_boss_scene.instantiate()
		get_tree().current_scene.add_child(sapo)
		sapo.global_position = global_position + Vector3(0.0, 1.0, 0.0)

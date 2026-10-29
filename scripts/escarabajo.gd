class_name Escarabajo
extends AliadoBase

@export var fuerza_empuje: float = 35.0

func _inicializar_aliado() -> void:
	velocidad = 2.5
	hp_maximo = 100.0
	hp = hp_maximo
	rango_ataque = 2.0
	intervalo_ataque = 2.0

# El escarabajo empuja a los enemigos
func _ejecutar_ataque_especifico(objetivo: Node3D) -> void:
	print("¡Escarabajo EMPUJA al enemigo!")
	if objetivo.has_method("recibir_impacto"):
		var dir_empuje := global_position.direction_to(objetivo.global_position)
		dir_empuje.y = 0.2
		objetivo.recibir_impacto(dir_empuje.normalized() * fuerza_empuje)

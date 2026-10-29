class_name Lagarto
extends AliadoBase

func _inicializar_aliado() -> void:
	velocidad = 6.0
	hp_maximo = 40.0
	hp = hp_maximo
	rango_ataque = 1.4
	intervalo_ataque = 1.0

# El lagarto mata a los enemigos de una sola mordida
func _ejecutar_ataque_especifico(objetivo: Node3D) -> void:
	print("¡Lagarto mata de una mordida a ", objetivo.name, "!")
	if objetivo.has_method("desaparecer"):
		objetivo.desaparecer()
	elif objetivo.has_method("recibir_dano"):
		objetivo.recibir_dano(9999.0)

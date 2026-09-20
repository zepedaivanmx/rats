class_name Hongo
extends Recolectable

# Definimos si el hongo penaliza el movimiento de la rata (heredado de Recolectable/Diseño general)
# Lo dejamos en false para que sea un objeto ligero por defecto.
# CORRECCIÓN: Se renombra a "es_pesado" para que la lógica de ratDad.gd lo lea correctamente.
@export var es_pesado: bool = false

# ==========================================
# INICIALIZACIÓN (Sobrescritura de la clase Padre)
# ==========================================
func _inicializar_recolectable() -> void:
	# Añadimos una etiqueta propia por si la madriguera o las raíces necesitan identificar 
	# específicamente que esto es un hongo y no un mineral.
	if not is_in_group("hongo"):
		add_to_group("hongo")
		
	# Para aprovechar la POO, añadimos una función exclusiva del hongo al nacer
	brotar_del_suelo()

# ==========================================
# FUNCIONES EXCLUSIVAS DEL HONGO
# ==========================================
func brotar_del_suelo() -> void:
	# Hacemos que el hongo empiece con tamaño 0
	scale = Vector3.ZERO
	
	# Usamos un Tween para animar su crecimiento y darle un aspecto jugoso y orgánico
	var tween = create_tween()
	# Escala a su tamaño normal (1,1,1) en 0.6 segundos, usando una transición de rebote (BOUNCE)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.6).set_trans(Tween.TRANS_BOUNCE)

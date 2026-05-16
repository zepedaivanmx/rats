extends RigidBody3D

var dano: float = 20.0
var ya_hizo_dano: bool = false # Para evitar daño múltiple por rebotes

func _ready() -> void:
	# 1. Configuración obligatoria para que el RigidBody detecte colisiones
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
	
	# 2. Destruir la piedra después de 20 segundos (dejándola en el campo mientras tanto)
	var timer = get_tree().create_timer(20.0)
	timer.timeout.connect(queue_free)

func _on_body_entered(body: Node) -> void:
	# Si choca con un enemigo y no ha hecho daño antes
	if not ya_hizo_dano and body.is_in_group("enemy"):
		if body.has_method("recibir_dano"):
			body.recibir_dano(dano)
			ya_hizo_dano = true # Marcamos que ya cumplió su función letal
			
			# Opcional: Si quieres que empuje al enemigo un poco al chocar
			if body.has_method("recibir_impacto"):
				var direccion_empuje = linear_velocity.normalized() * 5.0
				body.recibir_impacto(direccion_empuje)

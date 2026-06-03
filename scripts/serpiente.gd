extends PrimordialFather

@export var velocidad_rotacion: float = 2.0

func _ready() -> void:
	super() # Llama al _ready() de PrimordialFather para buscar a la rata y al árbol
	
	# Modificamos los stats base para la serpiente
	speed = 5.0 
	max_hp = 60.0
	hp = max_hp

# Sobrescribimos el movimiento para que solo haga su comportamiento circular
func _mover_y_actuar(delta: float) -> void:
	rotate_y(velocidad_rotacion * delta)
	
	var direccion_frente = -transform.basis.z.normalized()
	velocity.x = direccion_frente.x * speed
	velocity.z = direccion_frente.z * speed

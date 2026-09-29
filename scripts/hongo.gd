class_name Hongo extends Recolectable

@export var valor_base: int = 1
@export var valor_maduro: int = 2
@export var tiempo_madurez: float = 12.0   # a los 12 s vale el doble
@export var vida_util: float = 40.0        # a los 40 s se pudre
@export var tiempo_aviso: float = 5.0      # parpadea los últimos 5 s

var edad: float = 0.0
var maduro: bool = false
@onready var malla: MeshInstance3D = $MeshInstance3D

func _inicializar_recolectable() -> void:
	modo_recogida = ModoRecogida.INVENTARIO
	collision_layer = CAPA_RECOLECTABLE
	collision_mask = 1   # solo choca con el suelo
	valor = valor_base

# Solo corre en el suelo: dentro del inventario el reloj se congela
func _procesar_fisica_libre(delta: float) -> void:
	super(delta)
	edad += delta
	if not maduro and edad >= tiempo_madurez:
		maduro = true
		valor = valor_maduro
		malla.scale *= 1.5
	var restante := vida_util - edad
	if restante <= tiempo_aviso:
		malla.visible = int(edad * 6.0) % 2 == 0
	if restante <= 0.0:
		queue_free()

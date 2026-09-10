class_name Charco
extends ZonaAmbiental

@onready var aguas_profundas: Area3D = $AguasProfundas
var ratas_en_zona: Dictionary = {} # Diccionario para rastrear qué rata entró y su temporizador

func _ready() -> void:
	super()
	tipo_de_zona = TipoZona.CHARCO
	
	# Conexiones superficiales
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Conexiones profundas
	if aguas_profundas:
		aguas_profundas.body_entered.connect(_on_aguas_profundas_entered)

# --- LÓGICA DE AGUAS SUPERFICIALES ---
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("rats") and body.get("objeto_cargado") != null:
		# Inicia temporizador de 2 segundos en memoria
		var timer = get_tree().create_timer(2.0)
		ratas_en_zona[body] = timer 
		
		await timer.timeout
		
		# Si la rata sigue viva, sigue en el charco y sigue cargando algo
		if ratas_en_zona.has(body) and is_instance_valid(body.get("objeto_cargado")):
			var cadaver = body.soltar_objeto()
			if cadaver:
				procesar_cadaver(cadaver) # <--- Delegamos la putrefacción a la clase Padre

func _on_body_exited(body: Node3D) -> void:
	# Si la rata abandona el agua antes de los 2 segundos, abortamos la entrega
	if ratas_en_zona.has(body):
		ratas_en_zona.erase(body)

func _efecto_charco(cadaver: Node3D) -> void:
	# Aprovechamos la función que ya existe en PrimordialFather
	if cadaver.has_method("iniciar_putrefaccion"):
		cadaver.iniciar_putrefaccion() 
	else:
		# Si soltaste un mineral, puedes elegir si se pierde en el agua o rebota
		cadaver.queue_free()

# --- LÓGICA DE AGUAS PROFUNDAS (GAME OVER) ---
func _on_aguas_profundas_entered(body: Node3D) -> void:
	if body.is_in_group("rats") and body.has_method("activar_game_over"):
		body.activar_game_over()

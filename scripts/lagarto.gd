class_name Lagarto extends AliadoBase

var cooldown_ataque: float = 0.0
var enemigo_objetivo: Node3D = null
var estado_previo: EstadoAliado = EstadoAliado.IDLE

@onready var area_ataque: Area3D = $AreaAtaque

func _inicializar_aliado() -> void:
	velocidad = 6.0   
	hp_maximo = 40.0  
	hp = hp_maximo
	
	if area_ataque:
		area_ataque.body_entered.connect(_on_enemigo_detectado)
		area_ataque.body_exited.connect(_on_enemigo_perdido)

func _al_llegar_a_destino() -> void:
	seguir_al_jugador()

# --- SISTEMA DE DETECCIÓN SENSORIAL ---
func _on_enemigo_detectado(body: Node3D) -> void:
	if body.is_in_group("enemy") and estado_actual != EstadoAliado.ATACANDO:
		if body.has_method("esta_muerto") and body.esta_muerto: return
		
		enemigo_objetivo = body
		estado_previo = estado_actual
		estado_actual = EstadoAliado.ATACANDO

func _on_enemigo_perdido(body: Node3D) -> void:
	if body == enemigo_objetivo:
		_cancelar_ataque()

func _cancelar_ataque() -> void:
	enemigo_objetivo = null
	estado_actual = estado_previo

# --- LÓGICA OFENSIVA (MORDIDA) ---
func _procesar_ataque(delta: float) -> void:
	if not is_instance_valid(enemigo_objetivo) or (enemigo_objetivo.get("esta_muerto") == true):
		_cancelar_ataque()
		return

	var dist = global_position.distance_to(enemigo_objetivo.global_position)
	if dist > 1.2:
		_mover_hacia_objetivo(enemigo_objetivo.global_position)
	else:
		velocity.x = 0
		velocity.z = 0 # Se detiene para morder

	cooldown_ataque -= delta
	if cooldown_ataque <= 0.0 and dist <= 1.5:
		print("Lagarto MUERDE al enemigo!")
		if enemigo_objetivo.has_method("recibir_dano"):
			enemigo_objetivo.recibir_dano(20.0) # Aplica 20 de daño base
		cooldown_ataque = 1.0 # Muerde 1 vez por segundo

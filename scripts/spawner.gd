extends Node3D

# 1. Referencia a la escena del enemigo (arrastra el .tscn aquí en el inspector)
@export var enemy_scene: PackedScene

# 2. Configuración del área de aparición
@export var spawn_radius: float = 25.0 # Distancia desde el centro (árbol)
@export var spawn_container: Node3D # Nodo donde se guardarán los enemigos para tener orden

@onready var timer = $Timer

func _ready() -> void:
	# Conectamos la señal del Timer para que llame a la función cada vez que termine
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy() -> void:
	if not enemy_scene:
		return

	# 3. Crear la instancia (la copia)
	var enemy = enemy_scene.instantiate()

	# 4. Calcular una posición aleatoria en un círculo
	var angle = randf() * PI * 2 # Ángulo aleatorio entre 0 y 360 grados
	var spawn_pos = Vector3(
		cos(angle) * spawn_radius,
		0, # A ras de suelo
		sin(angle) * spawn_radius
	)

	# 5. Añadir el enemigo a la escena
	# Si definiste un contenedor, lo ponemos ahí; si no, en la raíz
	if spawn_container:
		spawn_container.add_child(enemy)
	else:
		get_parent().add_child(enemy)

	# Colocamos al enemigo en su posición inicial
	enemy.global_position = spawn_pos

class_name Charco extends ZonaAmbiental

func _ready() -> void:
	# Ejecutamos el ready del padre para activar el radar de cadáveres
	super() 
	# Asignamos la identidad de esta zona
	tipo_de_zona = TipoZona.CHARCO

# OMITIDO TEMPORALMENTE HASTA QUE RESPONDAS EL VACÍO DE DISEÑO:
# La lógica de AguasProfundas y muerte de la rata fue retirada para evitar errores de nodos nulos.

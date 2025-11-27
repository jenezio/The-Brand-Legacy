extends Camera2D

var target: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_target()


func _process(_delta: float) -> void:
	position = target.position

func get_target():
	var nodes = get_tree().get_nodes_in_group("jogador")
	if nodes.size() == 0:
		push_error("Jogador nao encontrado")
		return
		
	target = nodes[0]

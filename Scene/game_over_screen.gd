extends Control

func _ready() -> void:
    visible = false
    
    var player = get_tree().get_first_node_in_group("Player")
    if player and player.has_signal("player_died"):
        player.player_died.connect(_on_player_died)

func _on_player_died() -> void:
    visible = true
    get_tree().paused = true
    
    # Reiniciar após 3 segundos
    await get_tree().create_timer(3.0, true, false, true).timeout
    get_tree().paused = false
    get_tree().reload_current_scene()

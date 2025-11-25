extends CanvasLayer

@onready var Continuar = $Panel/menu_holder/Continuar
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		visible = true
		get_tree().paused = true
		Continuar.grab_focus()
func _on_continuar_pressed() -> void:
	get_tree().paused = false
	visible = false


func _on_sair_pressed() -> void:
	get_tree().quit()# Replace with function body.


func _on_reiniciar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

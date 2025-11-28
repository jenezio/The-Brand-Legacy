extends Control

func _ready():
	$VBoxContainer/start.grab_focus()
func _unhandled_input(event):
	if event.is_action_pressed("ui_down"):
		var current = get_viewport().gui_get_focus_owner()
		if current:
			current = current.get_focus_neighbor(SIDE_BOTTOM)
			if current:
				current.grab_focus()
	elif event.is_action_pressed("ui_up"):
		var current = get_viewport().gui_get_focus_owner()
		if current:
			current = current.get_focus_neighbor(SIDE_TOP)
			if current:
				current.grab_focus()
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/Tutorial.tscn") # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit() # Replace with function body.

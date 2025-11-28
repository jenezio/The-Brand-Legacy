extends CanvasLayer

signal dialog_started
signal dialog_finished

@onready var panel = $Panel
@onready var label = $Panel/Label
@onready var next_button = $Panel/Button   # << caminho correto

var dialog_lines: Array = []
var index: int = 0
var is_playing: bool = false

func _ready():
	# Garantindo que os nós existem
	if not panel:
		push_error("DialogoNPC ERROR: Nó Panel não encontrado. Caminho esperado: $Panel")
		return
	if not label:
		push_error("DialogoNPC ERROR: Nó Label não encontrado. Caminho esperado: $Panel/Label")
		return
	if not next_button:
		push_error("DialogoNPC WARNING: Botão não encontrado. Caminho esperado: $Panel/Button")
	else:
		next_button.pressed.connect(_on_next_pressed)

	panel.visible = false

func show_dialog(lines: Array):
	if lines.size() == 0:
		return

	dialog_lines = lines.duplicate()
	index = 0
	is_playing = true
	panel.visible = true

	emit_signal("dialog_started")
	_update_text()

func _on_next_pressed():
	index += 1

	if index >= dialog_lines.size():
		_end_dialog()
	else:
		_update_text()

func _update_text():
	if label:
		label.text = dialog_lines[index]

func _end_dialog():
	panel.visible = false
	is_playing = false
	emit_signal("dialog_finished")

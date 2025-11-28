extends CharacterBody2D

@export var dialog_text := [
	"Olá, viajante.",
	"Bem-vindo às ruínas de Tilambuco.",
    "Muito foi perdido... mas nem tudo está esquecido."
]

@onready var click_area: Area2D = $CliqueArea
@onready var proximity_area: Area2D = $ProximityArea
@onready var exclamacao: Sprite2D = $Exclamação
@onready var dialog_box = $DialogoNPC   # << Agora está dentro do NPC!

var player_in_range: bool = false

func _ready():
	# Conecta clique
	if click_area:
		click_area.input_event.connect(_on_click_area_input)
	else:
		push_error("NPC ERROR: CliqueArea não encontrado!")

	# Conecta proximidade
	if proximity_area:
		proximity_area.body_entered.connect(_on_proximity_entered)
		proximity_area.body_exited.connect(_on_proximity_exited)
	else:
		push_error("NPC ERROR: ProximityArea não encontrado!")

	# Conecta sinais do diálogo
	if dialog_box:
		dialog_box.dialog_started.connect(_on_dialog_started)
		dialog_box.dialog_finished.connect(_on_dialog_finished)
	else:
		push_error("NPC ERROR: DialogoNPC não encontrado como filho do NPC!")

	exclamacao.visible = true


func _on_click_area_input(_viewport, event, _shape_idx):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if player_in_range:
				dialog_box.show_dialog(dialog_text)



func _on_proximity_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		exclamacao.visible = false


func _on_proximity_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false

		if dialog_box and dialog_box.is_playing:
			exclamacao.visible = false
		else:
			exclamacao.visible = true


func _on_dialog_started():
	exclamacao.visible = false


func _on_dialog_finished():
	exclamacao.visible = false # conforme você pediu

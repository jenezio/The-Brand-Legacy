extends Control

@onready var btn_restart = $ColorRect/RestartButton
@onready var btn_quit = $ColorRect/QuitButton

func _ready():
    visible = false
    z_index = 1000
    z_as_relative = false
    
    _force_process_mode_recursive(self)
    
    print("GameOverScreen inicializado")
    
    if btn_restart:
        btn_restart.pressed.connect(_on_restart)
        print("RestartButton conectado")
    
    if btn_quit:
        btn_quit.pressed.connect(_on_quit)
        print("QuitButton conectado")
    
    call_deferred("_connect_player")

func _force_process_mode_recursive(node: Node):
    node.process_mode = Node.PROCESS_MODE_ALWAYS
    for child in node.get_children():
        _force_process_mode_recursive(child)

func _connect_player():
    var player = get_tree().get_first_node_in_group("Player")
    
    if player and player.has_signal("player_died"):
        player.player_died.connect(_on_player_died)
        print("Conectado ao player!")

func _on_player_died():
    print("")
    print("==================================================")
    print("GAME OVER ATIVADO!")
    print("==================================================")
    
    await get_tree().process_frame
    
    var viewport_size = get_viewport_rect().size
    set_size(viewport_size)
    set_position(Vector2.ZERO)
    
    visible = true
    z_index = 2000
    
    get_tree().paused = true
    
    # CONFIGURA MOUSE FILTERS
    var color_rect = $ColorRect
    if color_rect:
        color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    if btn_restart:
        btn_restart.mouse_filter = Control.MOUSE_FILTER_STOP
        btn_restart.disabled = false
        btn_restart.focus_mode = Control.FOCUS_ALL
    
    if btn_quit:
        btn_quit.mouse_filter = Control.MOUSE_FILTER_STOP
        btn_quit.disabled = false
        btn_quit.focus_mode = Control.FOCUS_ALL
    
    print("Tela visível!")
    print("Jogo pausado!")
    print("Clique nos botões!")
    print("==================================================")

func _input(event):
    if not visible:
        return
    
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        print("🖱️ CLIQUE em: ", event.position)
        
        if btn_restart and btn_restart.get_global_rect().has_point(event.position):
            print("Clicou no RESTART!")
            _on_restart()
        
        elif btn_quit and btn_quit.get_global_rect().has_point(event.position):
            print("Clicou no QUIT!")
            _on_quit()

func _on_restart():
    print("")
    print("REINICIANDO JOGO...")
    
    get_tree().paused = false
    get_tree().reload_current_scene()

func _on_quit():
    print("")
    print("👋 SAINDO DO JOGO...")
    
    get_tree().paused = false
    get_tree().quit()

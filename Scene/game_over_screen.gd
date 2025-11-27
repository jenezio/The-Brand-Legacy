extends Control

# ===========================================
# @ONREADY
# ===========================================
@onready var restart_button: Button = get_node_or_null("ColorRect/RestartButton")
@onready var quit_button: Button = get_node_or_null("ColorRect/QuitButton")
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

# ===========================================
# READY
# ===========================================
func _ready() -> void:
    # CRÍTICO: Permite funcionar mesmo com jogo pausado
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process_mode(Node.PROCESS_MODE_ALWAYS)

    for child in get_children():
        child.process_mode = Node.PROCESS_MODE_ALWAYS

    # Esconde a tela inicialmente
    visible = false
    
    # Debug
    print("🎮 GameOverScreen inicializado")
    print("  Process Mode: ", process_mode)
    print("  Process Mode ENUM: ", Node.PROCESS_MODE_ALWAYS)
    
    # Verifica e conecta os botões
    if restart_button:
        restart_button.pressed.connect(_on_restart_pressed)
        print("  ✅ RestartButton conectado")
    else:
        print("  ❌ RestartButton NÃO encontrado!")
    
    if quit_button:
        quit_button.pressed.connect(_on_quit_pressed)
        print("  ✅ QuitButton conectado")
    else:
        print("  ❌ QuitButton NÃO encontrado!")
    
    if animation_player:
        print("  ✅ AnimationPlayer encontrado")
    else:
        print("  ⚠️ AnimationPlayer não encontrado (opcional)")
    
    # Conecta ao player DEPOIS que a árvore estiver pronta
    call_deferred("_connect_to_player")

func _connect_to_player() -> void:
    """Conecta ao sinal de morte do player"""
    print("🔍 Procurando player...")
    
    var player = get_tree().get_first_node_in_group("Player")
    
    if player:
        print("  ✅ Player encontrado: ", player.name)
        
        if player.has_signal("player_died"):
            player.player_died.connect(_on_player_died)
            print("  ✅ Sinal 'player_died' conectado!")
        else:
            print("  ❌ Player não tem sinal 'player_died'!")
    else:
        print("  ❌ Player NÃO encontrado! Adicione ao grupo 'Player'")

# ===========================================
# CALLBACKS
# ===========================================
func _on_player_died() -> void:
    """Chamada quando o player morre"""
    print("")
    print("==================================================")
    print("💀 GAME OVER ATIVADO!")
    print("==================================================")
    
    # AGUARDA 1 FRAME para garantir que tudo processou
    await get_tree().process_frame
    
    # Mostra a tela
    visible = true
    print("  👁️ Tela visível: ", visible)
    
    # Pausa o jogo
    get_tree().paused = true
    print("  ⏸️ Jogo pausado: ", get_tree().paused)
    
    # Toca animação de fade in (se existir)
    if animation_player and animation_player.has_animation("fade_in"):
        animation_player.play("fade_in")
        print("  🎬 Animação 'fade_in' tocando")
    
    print("==================================================")

func _on_restart_pressed() -> void:
    """Reinicia o jogo"""
    print("")
    print("🔄 REINICIANDO JOGO...")
    
    # Despausa
    get_tree().paused = false
    
    # Recarrega a cena atual
    get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
    """Sai do jogo"""
    print("")
    print("👋 SAINDO DO JOGO...")
    
    # Despausa antes de sair
    get_tree().paused = false
    
    # Sai do jogo
    get_tree().quit()

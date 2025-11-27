extends ProgressBar

func _ready() -> void:
    # Busca o player pelo grupo
    var player = get_tree().get_first_node_in_group("Player")
    
    if player:
        # Conecta aos sinais do player
        if player.has_signal("health_changed"):
            player.health_changed.connect(_on_player_health_changed)
            print("✅ Sinal health_changed conectado!")
        
        if player.has_signal("player_died"):
            player.player_died.connect(_on_player_died)
            print("✅ Sinal player_died conectado!")
        
        # Inicializa os valores da barra
        max_value = player.max_vidas
        value = player.vidas
        
        print("💚 Barra de vida inicializada: ", value, "/", max_value)
    else:
        print("⚠️ ERRO: Player não encontrado! Adicione o Player ao grupo 'Player'")

func _on_player_health_changed(nova_vida: int) -> void:
    """Chamada quando a vida do player muda"""
    print("📊 Atualizando barra: ", nova_vida, "/", max_value)
    
    # Atualiza a barra com animação suave
    var tween = create_tween()
    tween.tween_property(self, "value", nova_vida, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    
    # Muda a cor baseado na porcentagem de vida
    var porcentagem_vida = float(nova_vida) / max_value
    
    if porcentagem_vida > 0.6:
        modulate = Color.GREEN  # Verde: Vida alta
    elif porcentagem_vida > 0.3:
        modulate = Color.YELLOW  # Amarelo: Vida média
    else:
        modulate = Color.RED  # Vermelho: Vida crítica

func _on_player_died() -> void:
    """Chamada quando o player morre"""
    print("💀 Player morreu! Game Over")
    value = 0
    modulate = Color.RED

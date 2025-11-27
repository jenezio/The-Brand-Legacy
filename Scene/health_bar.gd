extends ProgressBar

# ===========================================
# CONFIGURAÇÃO DE CORES
# ===========================================
const COLOR_BACKGROUND = Color(0x22 / 255.0, 0x01 / 255.0, 0x00 / 255.0)  # #220100 (fundo escuro)
const COLOR_FILL = Color(0x3e / 255.0, 0x03 / 255.0, 0x00 / 255.0)        # #3e0300 (vinho/sangue)
const COLOR_BORDER = Color(0x1a / 255.0, 0x01 / 255.0, 0x00 / 255.0)      # Borda mais escura
const COLOR_SHADOW = Color(0.0, 0.0, 0.0, 0.5)                            # Sombra preta

# ===========================================
# READY
# ===========================================
func _ready() -> void:
    # Configura o estilo da barra
    _setup_styles()
    
    # Busca o player
    var player = get_tree().get_first_node_in_group("Player")
    
    if player:
        # Conecta sinais
        if player.has_signal("health_changed"):
            player.health_changed.connect(_on_player_health_changed)
            print("✅ Sinal health_changed conectado!")
        
        if player.has_signal("player_died"):
            player.player_died.connect(_on_player_died)
            print("✅ Sinal player_died conectado!")
        
        # Inicializa valores
        max_value = player.max_vidas
        value = player.vidas
        
        print("🩸 Barra de vida inicializada: ", value, "/", max_value)
    else:
        print("⚠️ ERRO: Player não encontrado! Adicione ao grupo 'Player'")

func _setup_styles() -> void:
    """Configura os estilos da barra (background e fill)"""
    
    # ========== BACKGROUND (Fundo) ==========
    var bg_style = StyleBoxFlat.new()
    bg_style.bg_color = COLOR_BACKGROUND  # #220100
    bg_style.set_corner_radius_all(0)     # Quadrado (SEM cantos arredondados)
    
    # Borda externa
    bg_style.border_width_left = 3
    bg_style.border_width_right = 3
    bg_style.border_width_top = 3
    bg_style.border_width_bottom = 3
    bg_style.border_color = COLOR_BORDER
    
    # Sombra (profundidade)
    bg_style.shadow_color = COLOR_SHADOW
    bg_style.shadow_size = 4
    bg_style.shadow_offset = Vector2(2, 2)
    
    add_theme_stylebox_override("background", bg_style)
    
    # ========== FILL (Barra de vida) ==========
    var fill_style = StyleBoxFlat.new()
    fill_style.bg_color = COLOR_FILL  # #3e0300 (vinho/sangue)
    fill_style.set_corner_radius_all(0)  # Quadrado
    
    # Borda interna (destaque)
    fill_style.border_width_left = 1
    fill_style.border_width_right = 1
    fill_style.border_width_top = 1
    fill_style.border_width_bottom = 1
    fill_style.border_color = Color(0x6e / 255.0, 0x05 / 255.0, 0x00 / 255.0)  # Tom mais claro
    
    add_theme_stylebox_override("fill", fill_style)

# ===========================================
# CALLBACKS
# ===========================================
func _on_player_health_changed(nova_vida: int) -> void:
    """Vida mudou"""
    print("📊 Atualizando barra: ", nova_vida, "/", max_value)
    
    # Animação suave
    var tween = create_tween()
    tween.tween_property(self, "value", nova_vida, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_player_died() -> void:
    """Player morreu"""
    print("💀 Player morreu! Barra zerada")
    value = 0

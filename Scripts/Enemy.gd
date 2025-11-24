extends CharacterBody2D

# ===========================================
# ENUMERADORES
# ===========================================
enum State { PATROL, CHASE, ATTACK, HIT, DEAD }

# ===========================================
# EXPORTS
# ===========================================
@export_group("Movimento")
@export var patrol_speed := 60.0
@export var chase_speed := 100.0
@export var patrol_distance := 150.0

@export_group("Detecção")
@export var vision_distance := 250.0
@export var attack_range := 55.0

@export_group("Combate")
@export var attack_damage := 1
@export var max_health := 3
@export var attack_cooldown_time := 1.8

const GRAVITY := 980.0

# ===========================================
# VARIÁVEIS DE ESTADO
# ===========================================
var current_state = State.PATROL
var health := 3
var direction := 1  # Começa indo para DIREITA
var patrol_start_x: float
var is_attacking := false
var is_hitting := false
var is_dead := false
var can_attack := true

# ===========================================
# REFERÊNCIAS
# ===========================================
var player: Node2D = null
var distance_to_player := 999.0

# ===========================================
# NODOS
# ===========================================
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $colisor_padrao
@onready var damage_area: Area2D = $Area2D_DanoPlayer
@onready var vision_area: Area2D = $Area2D_Visao
@onready var wall_check: RayCast2D = $WallCheck

var attack_cooldown: Timer

# ===========================================
# INICIALIZAÇÃO
# ===========================================
func _ready() -> void:
    health = max_health
    patrol_start_x = global_position.x
    
    # Timer de Cooldown
    attack_cooldown = Timer.new()
    attack_cooldown.wait_time = attack_cooldown_time
    attack_cooldown.one_shot = true
    attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
    add_child(attack_cooldown)
    
    # Conectar sinal de animação
    if anim:
        if not anim.animation_finished.is_connected(_on_animation_finished):
            anim.animation_finished.connect(_on_animation_finished)
    
    # Buscar player
    call_deferred("_find_player")
    
    # Debug
    print("🦴 Inimigo inicializado. Vida: ", health)
    _play_animation("idle")

func _find_player() -> void:
    var players = get_tree().get_nodes_in_group("Player")
    if players.size() > 0:
        player = players[0]
        print("🎯 Player encontrado: ", player.name)
    else:
        print("⚠️ AVISO: Player não encontrado! Adicione o Player ao grupo 'Player'")

# ===========================================
# LOOP PRINCIPAL
# ===========================================
func _physics_process(delta: float) -> void:
    # Se morreu, para tudo
    if is_dead:
        velocity = Vector2.ZERO
        return
    
    # Gravidade
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    else:
        velocity.y = 0
    
    # Calcular distância até o player
    if is_instance_valid(player):
        distance_to_player = global_position.distance_to(player.global_position)
    
    # Máquina de Estados
    match current_state:
        State.PATROL:
            _state_patrol()
        State.CHASE:
            _state_chase()
        State.ATTACK:
            _state_attack()
        State.HIT:
            _state_hit()
        State.DEAD:
            _state_dead()
    
    move_and_slide()
    
    # Debug visual
    queue_redraw()

func _draw() -> void:
    # Debug: Desenha círculo de visão
    if OS.is_debug_build():
        draw_circle(Vector2.ZERO, vision_distance, Color(1, 0, 0, 0.1))
        draw_circle(Vector2.ZERO, attack_range, Color(1, 1, 0, 0.2))

# ===========================================
# ESTADOS
# ===========================================
func _state_patrol() -> void:
    # Se está levando hit, não se move
    if is_hitting:
        velocity.x = 0
        return
    
    # MOVIMENTO DE PATRULHA
    velocity.x = direction * patrol_speed
    _play_animation("walk")
    _update_sprite_direction()
    
    # Verifica se chegou no limite da patrulha
    var distance_from_start = abs(global_position.x - patrol_start_x)
    if distance_from_start >= patrol_distance:
        direction *= -1  # Inverte direção
        print("🔄 Inimigo inverteu direção na patrulha")
    
    # Verifica parede
    if wall_check:
        wall_check.target_position.x = direction * 25
        wall_check.force_raycast_update()
        if wall_check.is_colliding():
            direction *= -1
            print("🧱 Inimigo bateu na parede, invertendo")
    
    # TRANSIÇÃO: Se detectou o player, persegue
    if is_instance_valid(player) and distance_to_player < vision_distance:
        _change_state(State.CHASE)

func _state_chase() -> void:
    # Se está levando hit, não se move
    if is_hitting:
        velocity.x = 0
        return
    
    if not is_instance_valid(player):
        _change_state(State.PATROL)
        return
    
    # Calcula direção para o player
    if player.global_position.x > global_position.x:
        direction = 1  # Player está à direita
    else:
        direction = -1  # Player está à esquerda
    
    # MOVIMENTO DE PERSEGUIÇÃO
    velocity.x = direction * chase_speed
    _play_animation("walk")
    _update_sprite_direction()
    
    # TRANSIÇÃO: Se chegou perto e pode atacar
    if distance_to_player <= attack_range and can_attack:
        _change_state(State.ATTACK)
    
    # TRANSIÇÃO: Se o player fugiu muito, volta a patrulhar
    elif distance_to_player > vision_distance * 1.2:
        _change_state(State.PATROL)

func _state_attack() -> void:
    # Para de se mover
    velocity.x = 0
    
    # Vira para o player
    if is_instance_valid(player):
        if player.global_position.x > global_position.x:
            anim.flip_h = false
        else:
            anim.flip_h = true
    
    # Executa ataque uma vez
    if not is_attacking:
        is_attacking = true
        _play_animation("attack")
        print("⚔️ Inimigo está atacando!")

func _state_hit() -> void:
    # Para completamente
    velocity.x = 0
    # A animação já foi tocada no take_damage

func _state_dead() -> void:
    # Para completamente
    velocity.x = 0
    # A animação já foi tocada no take_damage

# ===========================================
# FUNÇÕES AUXILIARES
# ===========================================
func _change_state(new_state: State) -> void:
    if current_state == new_state:
        return
    
    var state_names = ["PATROL", "CHASE", "ATTACK", "HIT", "DEAD"]
    print("🔄 Estado: ", state_names[current_state], " → ", state_names[new_state])
    current_state = new_state

func _play_animation(anim_name: String) -> void:
    if not anim or not anim.sprite_frames:
        return
    
    # Verifica se a animação existe
    if not anim.sprite_frames.has_animation(anim_name):
        print("⚠️ Animação '", anim_name, "' não encontrada!")
        return
    
    # Só troca se for diferente
    if anim.animation != anim_name:
        anim.play(anim_name)
        print("🎬 Tocando animação: ", anim_name)

func _update_sprite_direction() -> void:
    if anim:
        anim.flip_h = (direction < 0)

# ===========================================
# SISTEMA DE DANO
# ===========================================
func take_damage(amount: int) -> void:
    if is_dead:
        print("⚠️ Inimigo já está morto, ignorando dano")
        return
    
    # Prevenir múltiplos hits simultâneos
    if is_hitting:
        print("⚠️ Inimigo já está em hit, ignorando dano adicional")
        return
    
    health -= amount
    print("💔 Inimigo levou ", amount, " de dano. Vida restante: ", health, "/", max_health)
    
    # VERIFICA MORTE PRIMEIRO
    if health <= 0:
        print("💀 Inimigo morreu!")
        is_dead = true
        is_hitting = true
        is_attacking = false
        can_attack = false
        
        _change_state(State.DEAD)
        _play_animation("dead")
        
        # Desabilita colisões
        if collision:
            collision.set_deferred("disabled", true)
        if damage_area:
            damage_area.monitoring = false
            damage_area.monitorable = false
        if vision_area:
            vision_area.monitoring = false
            vision_area.monitorable = false
        
        # Para o processamento
        set_physics_process(false)
        
    else:
        # APENAS HIT (não morreu)
        print("🩹 Inimigo levou hit")
        is_hitting = true
        is_attacking = false
        
        _change_state(State.HIT)
        _play_animation("hit")
        
        # Flash branco
        modulate = Color(3, 3, 3, 1)
        
        # Cria timer único para o flash
        var flash_timer = get_tree().create_timer(0.2)
        flash_timer.timeout.connect(func(): 
            if not is_dead:
                modulate = Color(1, 1, 1, 1)
        )

# ===========================================
# CALLBACKS DE ANIMAÇÃO
# ===========================================
func _on_animation_finished() -> void:
    if not anim:
        return
    
    var finished_anim = anim.animation
    print("✅ Animação finalizada: ", finished_anim)
    
    match finished_anim:
        "hit":
            # Hit terminou, volta ao combate
            is_hitting = false
            print("🩹 Hit terminou, voltando ao combate")
            
            if is_instance_valid(player) and distance_to_player < vision_distance:
                _change_state(State.CHASE)
            else:
                _change_state(State.PATROL)
        
        "attack":
            # Ataque terminou
            is_attacking = false
            can_attack = false
            attack_cooldown.start()
            print("⚔️ Ataque terminou, cooldown iniciado")
            
            # Volta a perseguir
            if is_instance_valid(player) and distance_to_player < vision_distance:
                _change_state(State.CHASE)
            else:
                _change_state(State.PATROL)
        
        "dead":
            # Morte finalizada, remove o inimigo
            print("💀 Animação de morte terminou, removendo inimigo")
            queue_free()

func _on_attack_cooldown_timeout() -> void:
    can_attack = true
    print("✅ Cooldown de ataque terminou")

# ===========================================
# SINAIS DAS ÁREAS
# ===========================================
func _on_area_2d_dano_player_body_entered(body: Node2D) -> void:
    # Só causa dano se:
    # 1. Está no estado de ataque
    # 2. Não está morto
    # 3. Não está levando hit
    # 4. O corpo é o player
    
    if not is_attacking:
        return
    
    if is_dead or is_hitting:
        return
    
    if not body.is_in_group("Player"):
        return
    
    if body.has_method("take_damage"):
        body.take_damage(attack_damage)
        print("💥 ACERTOU O PLAYER! Causou ", attack_damage, " de dano!")

func _on_area_2d_visao_body_entered(body: Node2D) -> void:
    if body.is_in_group("Player") and not is_dead:
        player = body
        print("👁️ Player entrou na visão!")
        
        if current_state == State.PATROL:
            _change_state(State.CHASE)

func _on_area_2d_visao_body_exited(body: Node2D) -> void:
    if body == player and not is_dead:
        print("👁️ Player saiu da visão!")
        
        if current_state == State.CHASE:
            _change_state(State.PATROL)

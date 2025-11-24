extends CharacterBody2D
class_name SkeletonEnemy

# --- Configurações (Ajuste no Inspector) ---
@export_category("Movimento")
@export var speed: float = 100.0
@export var gravity: float = 980.0
@export var knockback_force: float = 200.0

@export_category("Combate")
@export var health: int = 3
@export var detection_range: float = 250.0 # Distância para começar a seguir
@export var attack_range: float = 35.0     # Distância para parar e atacar
@export var damage_amount: int = 1

# --- Referências (Nós Filhos) ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hitbox_col: CollisionShape2D = $HitboxArea/CollisionShape2D

# --- Variáveis Internas ---
var player: Node2D = null
enum State { IDLE, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE

func _ready() -> void:
    # Configuração inicial da navegação
    nav_agent.path_desired_distance = 15.0
    nav_agent.target_desired_distance = 10.0
    
    # Busca o jogador pelo GRUPO (Passo crucial!)
    var players = get_tree().get_nodes_in_group("Player")
    if players.size() > 0:
        player = players[0]
    
    # Garante que a animação comece correta
    _update_animation("idle")

func _physics_process(delta: float) -> void:
    # Aplica gravidade sempre (exceto se morto e no chão)
    if not is_on_floor():
        velocity.y += gravity * delta

    match current_state:
        State.IDLE:
            _process_idle(delta)
        State.CHASE:
            _process_chase(delta)
        State.ATTACK:
            _process_attack(delta)
        State.HURT:
            _process_hurt(delta)
        State.DEAD:
            pass # Não faz nada, só espera ser removido

    move_and_slide()

# --- Lógica dos Estados ---

func _process_idle(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0, speed * delta) # Freia suavemente
    _update_animation("idle")
    
    if _can_see_player():
        current_state = State.CHASE

func _process_chase(delta: float) -> void:
    if not player: return
    
    var dist_to_player = global_position.distance_to(player.global_position)
    
    # Se chegou perto o suficiente, ataca
    if dist_to_player <= attack_range:
        current_state = State.ATTACK
        velocity.x = 0
        return
        
    # Se o jogador fugiu muito, desiste
    if dist_to_player > detection_range * 1.5:
        current_state = State.IDLE
        return

    # Lógica de Navegação (NavigationAgent)
    nav_agent.target_position = player.global_position
    
    # Verifica se o mapa de navegação está pronto
    if nav_agent.is_navigation_finished():
        return

    var current_agent_pos = global_position
    var next_path_pos = nav_agent.get_next_path_position()
    var direction = current_agent_pos.direction_to(next_path_pos)
    
    velocity.x = direction.x * speed
    _flip_sprite(velocity.x)
    _update_animation("walk")

func _process_attack(delta: float) -> void:
    # Toca animação e espera ela acabar
    _update_animation("attack")
    
    # Nota: O dano real deve ser aplicado via AnimationPlayer ou checando o frame da animação,
    # mas aqui usamos o fim da animação para voltar a perseguir.
    if not sprite.is_playing() or sprite.animation != "attack":
        # Se a animação acabou, volta a perseguir
        current_state = State.CHASE

func _process_hurt(delta: float) -> void:
    # Aplica fricção forte para parar o empurrão (knockback)
    velocity.x = move_toward(velocity.x, 0, 300 * delta)
    
    if not sprite.is_playing() or sprite.animation != "hit":
        current_state = State.CHASE

# --- Funções Públicas (Chamadas por outros scripts) ---

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
    if current_state == State.DEAD: return
    
    health -= amount
    
    if health <= 0:
        die()
    else:
        current_state = State.HURT
        _update_animation("hit")
        
        # Calcula direção do empurrão (oposto ao atacante)
        if attacker_pos != Vector2.ZERO:
            var knock_dir = (global_position - attacker_pos).normalized()
            velocity = knock_dir * knockback_force
            velocity.y = -150 # Um pulinho para cima ao tomar dano

func die() -> void:
    current_state = State.DEAD
    velocity = Vector2.ZERO
    _update_animation("death")
    
    # Desativa colisões
    $CollisionShape2D.set_deferred("disabled", true)
    $HitboxArea/CollisionShape2D.set_deferred("disabled", true)
    $DetectionArea/CollisionShape2D.set_deferred("disabled", true)
    
    # Espera animação e some
    await sprite.animation_finished
    queue_free()

# --- Auxiliares ---

func _update_animation(anim_name: String) -> void:
    if sprite.animation != anim_name:
        sprite.play(anim_name)

func _flip_sprite(x_velocity: float) -> void:
    if x_velocity != 0:
        sprite.flip_h = x_velocity < 0 # Se for negativo (esquerda), vira o sprite

func _can_see_player() -> bool:
    if not player: return false
    return global_position.distance_to(player.global_position) < detection_range

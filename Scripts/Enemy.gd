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
@export var patrol_distance := 150.0  # Distância total de patrulha (ponto A até ponto B)

@export_group("Detecção")
@export var vision_distance := 250.0
@export var attack_range := 55.0
@onready var hit_skeleton: AudioStreamPlayer = $hit_skeleton
@onready var attack_skeleton: AudioStreamPlayer = $attack_skeleton
@onready var die_skeleton: AudioStreamPlayer = $die_skeleton

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
var direction := 1
var patrol_point_a: float  # Ponto inicial da patrulha
var patrol_point_b: float  # Ponto final da patrulha
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
@onready var collision: CollisionShape2D = get_node_or_null("colisor_padrao")
@onready var damage_area: Area2D = $Area2D_DanoPlayer
@onready var vision_area: Area2D = $Area2D_Visao
@onready var wall_check: RayCast2D = $WallCheck

var attack_cooldown: Timer

# ===========================================
# INICIALIZAÇÃO
# ===========================================
func _ready() -> void:
	health = max_health
	
	# ========== CONFIGURA PONTOS DE PATRULHA ==========
	patrol_point_a = global_position.x - (patrol_distance / 2)
	patrol_point_b = global_position.x + (patrol_distance / 2)
	
	# Inicia indo para a direita
	direction = 1
	
	print("🚶 Patrulha configurada:")
	print("  Ponto A (esquerda): ", patrol_point_a)
	print("  Ponto B (direita): ", patrol_point_b)
	print("  Distância total: ", patrol_distance)
	# =================================================
	
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
	
	# Conectar sinal da área de dano
	if damage_area:
		if not damage_area.body_entered.is_connected(_on_area_2d_dano_player_body_entered):
			damage_area.body_entered.connect(_on_area_2d_dano_player_body_entered)
		else:
			print("⚠️ Sinal body_entered JÁ estava conectado")
	
	# Conectar sinais da área de visão
	if vision_area:
		if not vision_area.body_entered.is_connected(_on_area_2d_visao_body_entered):
			vision_area.body_entered.connect(_on_area_2d_visao_body_entered)
		if not vision_area.body_exited.is_connected(_on_area_2d_visao_body_exited):
			vision_area.body_exited.connect(_on_area_2d_visao_body_exited)
	
	# Buscar player
	call_deferred("_find_player")
	
	print("🦴 Inimigo inicializado. Vida: ", health)
	_play_animation("idle")

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		print("🎯 Player encontrado: ", player.name)
	else:
		print("⚠️ AVISO: Player não encontrado!")

# ===========================================
# LOOP PRINCIPAL
# ===========================================
func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
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

# ===========================================
# ESTADOS
# ===========================================
func _state_patrol() -> void:
	if is_hitting:
		velocity.x = 0
		return
	
	velocity.x = direction * patrol_speed
	_play_animation("walk")
	_update_sprite_direction()
	
	# ========== LÓGICA DE PATRULHA MELHORADA ==========
	# Verifica se chegou no ponto B (direita)
	if direction > 0 and global_position.x >= patrol_point_b:
		direction = -1
		print("🔄 Chegou no ponto B, virando para esquerda")
	
	# Verifica se chegou no ponto A (esquerda)
	elif direction < 0 and global_position.x <= patrol_point_a:
		direction = 1
		print("🔄 Chegou no ponto A, virando para direita")
	# =================================================
	
	# Detecção de parede
	if wall_check:
		wall_check.target_position.x = direction * 25
		wall_check.force_raycast_update()
		if wall_check.is_colliding():
			direction *= -1
			print("🧱 Bateu na parede, invertendo direção")
	
	# Detecta player
	if is_instance_valid(player) and distance_to_player < vision_distance:
		_change_state(State.CHASE)

func _state_chase() -> void:
	if is_hitting:
		velocity.x = 0
		return
	
	if not is_instance_valid(player):
		_change_state(State.PATROL)
		return
	
	if player.global_position.x > global_position.x:
		direction = 1
	else:
		direction = -1
	
	velocity.x = direction * chase_speed
	_play_animation("walk")
	_update_sprite_direction()
	
	if distance_to_player <= attack_range and can_attack:
		_change_state(State.ATTACK)
	elif distance_to_player > vision_distance * 1.2:
		_change_state(State.PATROL)

func _state_attack() -> void:
	velocity.x = 0
	
	if is_instance_valid(player):
		if player.global_position.x > global_position.x:
			anim.flip_h = false
		else:
			anim.flip_h = true
	
	if not is_attacking:
		is_attacking = true
		
		if damage_area:
			damage_area.monitoring = true
		
		_play_animation("attack")
		attack_skeleton.play()
		print("⚔️ Inimigo está atacando!")

func _state_hit() -> void:
	velocity.x = 0

func _state_dead() -> void:
	velocity.x = 0

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
	
	if not anim.sprite_frames.has_animation(anim_name):
		return
	
	if anim.animation != anim_name:
		anim.play(anim_name)

func _update_sprite_direction() -> void:
	if anim:
		anim.flip_h = (direction < 0)

# ===========================================
# SISTEMA DE DANO
# ===========================================
func take_damage(amount: int) -> void:
	if is_dead or is_hitting:
		return
	
	health -= amount
	hit_skeleton.play()
	print("💔 Inimigo levou ", amount, " de dano. Vida restante: ", health, "/", max_health)
	
	if health <= 0:
		die_skeleton.play()
		print("💀 Inimigo morreu!")
		is_dead = true
		is_hitting = true
		is_attacking = false
		can_attack = false
		
		_change_state(State.DEAD)
		_play_animation("dead")
		
		if collision:
			collision.set_deferred("disabled", true)
		
		if damage_area:
			damage_area.set_deferred("monitoring", false)
			damage_area.set_deferred("monitorable", false)
		
		if vision_area:
			vision_area.set_deferred("monitoring", false)
			vision_area.set_deferred("monitorable", false)
		
		set_physics_process(false)
		
	else:
		print("🩹 Inimigo levou hit")
		is_hitting = true
		is_attacking = false
		
		_change_state(State.HIT)
		_play_animation("hit")
		
		modulate = Color(3, 3, 3, 1)
		
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
	
	match finished_anim:
		"hit":
			is_hitting = false
			print("🩹 Hit terminou")
			
			if is_instance_valid(player) and distance_to_player < vision_distance:
				_change_state(State.CHASE)
			else:
				_change_state(State.PATROL)
		
		"attack":
			is_attacking = false
			can_attack = false
			attack_cooldown.start()
			print("⚔️ Ataque terminou")
			
			if damage_area:
				damage_area.monitoring = false
			
			if is_instance_valid(player) and distance_to_player < vision_distance:
				_change_state(State.CHASE)
			else:
				_change_state(State.PATROL)
		
		"dead":
			print("💀 Removendo inimigo")
			queue_free()

func _on_attack_cooldown_timeout() -> void:
	can_attack = true
	print("✅ Cooldown terminou")

# ===========================================
# SINAIS DAS ÁREAS
# ===========================================
func _on_area_2d_dano_player_body_entered(body: Node2D) -> void:
	if not is_attacking or is_dead or is_hitting:
		return
	
	if not body.is_in_group("Player"):
		return
	
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)
		print("💥 Acertou o player!")

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

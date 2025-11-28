extends CharacterBody2D

# ===========================================
# SINAIS
# ===========================================
signal health_changed(nova_vida: int)
signal player_died()

# ===========================================
# @ONREADY
# ===========================================
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Area2D_Ataque

# ===========================================
# @EXPORT
# ===========================================
@export_group("Movimento")
@export var speed := 120.0
@export var jump_force := -300.0
@export var gravity := 900.0

@export_group("Combate")
@export var max_vidas := 5
@export var invencibility_time := 1.0

@export_group("Debug")
@export var show_debug_info := true

# ===========================================
# VARIÁVEIS
# ===========================================
var vidas := 5
var is_attacking := false
var has_damaged := false
var is_dead := false
var is_hurt := false
var is_invincible := false

var invincibility_timer: Timer
var hurt_animation_timer: Timer

# ===========================================
# READY
# ===========================================
func _ready() -> void:
	vidas = max_vidas
	attack_area.monitoring = false

	_setup_timers()
	_connect_signals()

	if show_debug_info:
		print("🎮 Player inicializado. Vida: ", vidas, "/", max_vidas)

func _setup_timers() -> void:
	

	# Timer de invencibilidade
	invincibility_timer = Timer.new()
	invincibility_timer.wait_time = invencibility_time
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(invincibility_timer)

	# Timer de hurt
	hurt_animation_timer = Timer.new()
	hurt_animation_timer.wait_time = 0.4
	hurt_animation_timer.one_shot = true
	hurt_animation_timer.timeout.connect(_on_hurt_animation_timeout)
	add_child(hurt_animation_timer)

func _connect_signals() -> void:
	
	if not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)
		if show_debug_info:
			print("✅ Sinais conectados")

# ===========================================
# PHYSICS
# ===========================================
func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_hurt:
		velocity.x = 0
		_apply_gravity(delta)
		move_and_slide()
		return

	if is_attacking and anim.animation != "attack_model1":
		_reset_attack()

	_apply_gravity(delta)
	_handle_input()
	_update_animations()

	move_and_slide()

func _apply_gravity(delta: float) -> void:
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

func _handle_input() -> void:
	

	if Input.is_action_just_pressed("ataque") and is_on_floor() and not is_attacking:
		_start_attack()
		return

	if is_attacking:
		velocity.x = 0
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		if show_debug_info:
			print("⬆️ Pulo!")

	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = direction * speed
		anim.scale.x = direction
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func _update_animations() -> void:
	

	if is_dead or is_hurt or is_attacking:
		return

	if not is_on_floor():
		_play_animation("jump")
	else:
		if abs(velocity.x) > 10:
			_play_animation("walk")
		else:
			_play_animation("idle")

func _play_animation(anim_name: String) -> void:
	
	if anim.animation != anim_name:
		anim.play(anim_name)

# ===========================================
# ATAQUE
# ===========================================
func _start_attack() -> void:
	
	is_attacking = true
	has_damaged = false
	velocity.x = 0
	attack_area.monitoring = true
	_play_animation("attack_model1")

	if show_debug_info:
		print("⚔️ Atacando!")

func _reset_attack() -> void:
	
	is_attacking = false
	attack_area.monitoring = false
	has_damaged = false

# ===========================================
# DANO
# ===========================================
func take_damage(amount: int) -> void:
	

	if is_dead or is_invincible:
		if show_debug_info and is_invincible:
			print("🛡️ Invencível!")
		return

	if is_hurt:
		return

	vidas -= amount

	if show_debug_info:
		print("💔 Levou ", amount, " de dano! Vidas: ", vidas, "/", max_vidas)

	health_changed.emit(vidas)

	if vidas <= 0:
		_player_death()
	else:
		_player_hurt()

func _player_hurt() -> void:
	
	is_hurt = true
	velocity = Vector2.ZERO

	if is_attacking:
		_reset_attack()

	_play_animation("hurt")
	_flash_damage()

	is_invincible = true
	invincibility_timer.start()
	hurt_animation_timer.start()

	if show_debug_info:
		print("🤕 Levou hit!")

func _player_death() -> void:
   
	is_dead = true
	is_hurt = false
	is_attacking = false
	velocity = Vector2.ZERO

	# Para timers
	if invincibility_timer and invincibility_timer.time_left > 0:
		invincibility_timer.stop()
	if hurt_animation_timer and hurt_animation_timer.time_left > 0:
		hurt_animation_timer.stop()

	if show_debug_info:
		print("💀 Player morreu!")

	# ========== EMITE SINAL ANTES DE DESATIVAR! ==========
	player_died.emit()
	print("📡 Sinal 'player_died' emitido!")
	# ====================================================

	# Desativa física DEPOIS de emitir o sinal
	set_physics_process(false)

	# Toca animação de morte
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("death"):
		_play_animation("death")
	else:
		# Se não tem animação de morte, aguarda um pouco antes de sumir
		await get_tree().create_timer(1.0).timeout
		queue_free()

# ===========================================
# TIMERS
# ===========================================
func _on_invincibility_timeout() -> void:
	
	is_invincible = false
	modulate = Color(1, 1, 1, 1)

	if show_debug_info:
		print("🛡️ Invencibilidade OFF")

func _on_hurt_animation_timeout() -> void:
	
	is_hurt = false

	if show_debug_info:
		print("✅ Hurt terminou")

# ===========================================
# ANIMAÇÃO FINISHED
# ===========================================
func _on_animation_finished() -> void:
	
	var finished_anim = anim.animation

	match finished_anim:
		"attack_model1":
			_reset_attack()
			if show_debug_info:
				print("✅ Ataque terminou")

		"hurt":
			pass

		"death":
			if show_debug_info:
				print("💀 Removendo player")
			await get_tree().create_timer(1.0).timeout
			queue_free()

# ===========================================
# EFEITOS
# ===========================================
func _flash_damage() -> void:
	
	modulate = Color(5, 0.5, 0.5, 1)
	await get_tree().create_timer(0.15).timeout

	if not is_dead:
		if is_invincible:
			_start_invincibility_flicker()
		else:
			modulate = Color(1, 1, 1, 1)

func _start_invincibility_flicker() -> void:
	
	var flicker_time = 0.1
	var total_time = invencibility_time
	var elapsed = 0.0

	while elapsed < total_time and is_invincible:
		modulate.a = 0.5
		await get_tree().create_timer(flicker_time).timeout
		elapsed += flicker_time

		if not is_invincible:
			break

		modulate.a = 1.0
		await get_tree().create_timer(flicker_time).timeout
		elapsed += flicker_time

	modulate = Color(1, 1, 1, 1)

# ===========================================
# COLISÃO DE ATAQUE
# ===========================================
func _on_area_2d_ataque_body_entered(body: Node2D) -> void:
	

	if not is_attacking or has_damaged:
		return

	if not body.is_in_group("Enemy"):
		return

	var enemy = body as CharacterBody2D
	if enemy == null:
		return

	if not enemy.has_method("take_damage"):
		return

	if enemy.is_hitting or enemy.is_dead:
		return

	enemy.take_damage(1)
	has_damaged = true

	if show_debug_info:
		print("⚔️ Acertou inimigo!")
